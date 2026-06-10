#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_workflows.py
產生 ComfyUI 工作站的 7 個 workflow.json（ComfyUI UI 格式 / version 0.4）。

設計重點：
  - 用 Graph builder 統一管理 node id 與 link id，避免手寫連線出錯。
  - 節點採用 ComfyUI 核心 + 常用自訂節點的標準 input/output 插槽順序。
  - 產生後會自我驗證：所有 link 端點都指向存在的 node/slot。
  - 模型名稱對應 03_download_models.ps1 下載後的正規檔名；
    在 ComfyUI 載入後，若下拉選單顯示紅框，重新選一次即可。

輸出位置： ../ComfyUI_Workflows/<分類>/<名稱>.json
"""
import json, os

OUT = os.path.join(os.path.dirname(__file__), "..", "ComfyUI_Workflows")

class Graph:
    def __init__(self):
        self.nodes = []
        self.links = []
        self.nid = 0
        self.lid = 0
        self._by_id = {}

    def node(self, type, pos, inputs=None, outputs=None, widgets=None, size=None, title=None):
        self.nid += 1
        n = {
            "id": self.nid,
            "type": type,
            "pos": pos,
            "size": size or [320, 200],
            "flags": {},
            "order": 0,
            "mode": 0,
            "inputs":  [{"name": i[0], "type": i[1], "link": None} for i in (inputs or [])],
            "outputs": [{"name": o[0], "type": o[1], "links": [], "slot_index": idx}
                        for idx, o in enumerate(outputs or [])],
            "properties": {"Node name for S&R": type},
            "widgets_values": widgets if widgets is not None else [],
        }
        if title:
            n["title"] = title
        self.nodes.append(n)
        self._by_id[self.nid] = n
        return self.nid

    def link(self, src, src_slot, dst, dst_slot, type):
        self.lid += 1
        self.links.append([self.lid, src, src_slot, dst, dst_slot, type])
        s = self._by_id[src]["outputs"][src_slot]
        s["links"].append(self.lid)
        self._by_id[dst]["inputs"][dst_slot]["link"] = self.lid
        return self.lid

    def validate(self):
        for ln in self.links:
            lid, s, ss, d, ds, t = ln
            assert s in self._by_id, f"link {lid}: 來源 node {s} 不存在"
            assert d in self._by_id, f"link {lid}: 目標 node {d} 不存在"
            assert ss < len(self._by_id[s]["outputs"]), f"link {lid}: 來源 slot {ss} 超出範圍"
            assert ds < len(self._by_id[d]["inputs"]),  f"link {lid}: 目標 slot {ds} 超出範圍"

    def save(self, sub, name):
        self.validate()
        for i, n in enumerate(self.nodes):
            n["order"] = i
        data = {
            "last_node_id": self.nid,
            "last_link_id": self.lid,
            "nodes": self.nodes,
            "links": self.links,
            "groups": [],
            "config": {},
            "extra": {},
            "version": 0.4,
        }
        d = os.path.join(OUT, sub)
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, name)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"  [OK] {sub}/{name}  ({len(self.nodes)} nodes, {len(self.links)} links)")


# ===== 可重用的子圖 =====

def flux_loaders(g, unet, x=-1600, y=-200):
    """載入 FLUX：UNET + DualCLIP + VAE，回傳 (model, clip, vae) node id"""
    m = g.node("UNETLoader", [x, y], outputs=[("MODEL", "MODEL")],
               widgets=[unet, "default"], title="FLUX UNet")
    c = g.node("DualCLIPLoader", [x, y+140],
               outputs=[("CLIP", "CLIP")],
               widgets=["t5xxl_fp16.safetensors", "clip_l.safetensors", "flux", "default"],
               title="FLUX Text Encoders")
    v = g.node("VAELoader", [x, y+320], outputs=[("VAE", "VAE")],
               widgets=["flux_ae.safetensors"], title="FLUX VAE")
    return m, c, v

def flux_text(g, clip, prompt, x, y, guidance=3.5, title="Prompt"):
    """CLIPTextEncode -> FluxGuidance，回傳 conditioning node/slot"""
    t = g.node("CLIPTextEncode", [x, y], inputs=[("clip", "CLIP")],
               outputs=[("CONDITIONING", "CONDITIONING")], widgets=[prompt],
               size=[360, 160], title=title)
    g.link(clip, 0, t, 0, "CLIP")
    fg = g.node("FluxGuidance", [x+380, y], inputs=[("conditioning", "CONDITIONING")],
                outputs=[("CONDITIONING", "CONDITIONING")], widgets=[guidance],
                title="FluxGuidance")
    g.link(t, 0, fg, 0, "CONDITIONING")
    return fg

def flux_sampler(g, model, pos_cond, latent, steps, x, y, seed=0, denoise=1.0, sampler="euler", sched="simple"):
    """FLUX 標準自訂取樣鏈，回傳輸出 LATENT 的 (node,slot)"""
    noise = g.node("RandomNoise", [x, y], outputs=[("NOISE", "NOISE")],
                   widgets=[seed, "randomize"], title="RandomNoise")
    ks = g.node("KSamplerSelect", [x, y+120], outputs=[("SAMPLER", "SAMPLER")],
                widgets=[sampler], title="Sampler")
    sched_n = g.node("BasicScheduler", [x, y+220], inputs=[("model", "MODEL")],
                     outputs=[("SIGMAS", "SIGMAS")], widgets=[sched, steps, denoise],
                     title="Scheduler")
    g.link(model, 0, sched_n, 0, "MODEL")
    guider = g.node("BasicGuider", [x, y+360],
                    inputs=[("model", "MODEL"), ("conditioning", "CONDITIONING")],
                    outputs=[("GUIDER", "GUIDER")], title="Guider")
    g.link(model, 0, guider, 0, "MODEL")
    g.link(pos_cond, 0, guider, 1, "CONDITIONING")
    sca = g.node("SamplerCustomAdvanced", [x+320, y+120],
                 inputs=[("noise", "NOISE"), ("guider", "GUIDER"),
                         ("sampler", "SAMPLER"), ("sigmas", "SIGMAS"),
                         ("latent_image", "LATENT")],
                 outputs=[("output", "LATENT"), ("denoised_output", "LATENT")],
                 title="SamplerCustomAdvanced")
    g.link(noise, 0, sca, 0, "NOISE")
    g.link(guider, 0, sca, 1, "GUIDER")
    g.link(ks, 0, sca, 2, "SAMPLER")
    g.link(sched_n, 0, sca, 3, "SIGMAS")
    g.link(latent[0], latent[1], sca, 4, "LATENT")
    return (sca, 0)

def save_image(g, image_no, image_slot, x, y, prefix="Output"):
    s = g.node("SaveImage", [x, y], inputs=[("images", "IMAGE")],
               widgets=[prefix], size=[400, 400], title="Save")
    g.link(image_no, image_slot, s, 0, "IMAGE")
    return s

def vae_decode(g, latent, vae, x, y):
    d = g.node("VAEDecode", [x, y], inputs=[("samples", "LATENT"), ("vae", "VAE")],
               outputs=[("IMAGE", "IMAGE")], title="VAE Decode")
    g.link(latent[0], latent[1], d, 0, "LATENT")
    g.link(vae, 0, d, 1, "VAE")
    return d


# ============================================================
#  工作流 1：Architecture Pro  (CAD -> 建築渲染)
# ============================================================
def wf_architecture():
    g = Graph()
    # 來源：CAD 截圖
    img = g.node("LoadImage", [-2000, 200], outputs=[("IMAGE", "IMAGE"), ("MASK", "MASK")],
                 widgets=["cad_screenshot.png", "image"], title="CAD 截圖")
    # LineArt 預處理
    line = g.node("LineArtPreprocessor", [-1640, 200],
                  inputs=[("image", "IMAGE")], outputs=[("IMAGE", "IMAGE")],
                  widgets=["enable", 1024], title="LineArt 預處理")
    g.link(img, 0, line, 0, "IMAGE")

    # FLUX 載入 (Kontext dev 作為主力建築渲染)
    model, clip, vae = flux_loaders(g, "flux1-kontext-dev.safetensors", x=-2000, y=-360)
    pos = flux_text(g, clip, "professional architectural rendering, modern residential building, "
                             "daytime, clear blue sky, photorealistic, ultra detailed, 8k", -1600, -380, 3.5, "正向(日景/住宅)")
    neg = flux_text(g, clip, "blurry, low quality, distorted, cartoon", -1600, -180, 3.5, "負向")

    # ControlNet (FLUX union) 套用 lineart
    cn = g.node("ControlNetLoader", [-1240, 60], outputs=[("CONTROL_NET", "CONTROL_NET")],
                widgets=["flux_controlnet_union_pro_2.safetensors"], title="FLUX ControlNet")
    cnapply = g.node("ControlNetApplyAdvanced", [-1000, -100],
                     inputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING"),
                             ("control_net", "CONTROL_NET"), ("image", "IMAGE"), ("vae", "VAE")],
                     outputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING")],
                     widgets=[0.65, 0.0, 0.8], title="套用 ControlNet")
    g.link(pos, 0, cnapply, 0, "CONDITIONING")
    g.link(neg, 0, cnapply, 1, "CONDITIONING")
    g.link(cn, 0, cnapply, 2, "CONTROL_NET")
    g.link(line, 0, cnapply, 3, "IMAGE")
    g.link(vae, 0, cnapply, 4, "VAE")

    # Latent (1536x1536)
    lat = g.node("EmptySD3LatentImage", [-1000, 220], outputs=[("LATENT", "LATENT")],
                 widgets=[1536, 1536, 1], title="Latent 1536")

    out = flux_sampler(g, model, cnapply, (lat, 0), steps=24, x=-600, y=-100, seed=0)
    dec = vae_decode(g, out, vae, -120, -100)

    # Ultimate SD Upscale（用 RealVisXL + 放大模型精修）
    upscaler = g.node("UpscaleModelLoader", [-120, 120], outputs=[("UPSCALE_MODEL", "UPSCALE_MODEL")],
                      widgets=["4x-UltraSharp.pth"], title="放大模型")
    ckpt = g.node("CheckpointLoaderSimple", [-120, 260],
                  outputs=[("MODEL", "MODEL"), ("CLIP", "CLIP"), ("VAE", "VAE")],
                  widgets=["RealVisXL_V5.0_fp16.safetensors"], title="RealVisXL (精修放大)")
    pos2 = g.node("CLIPTextEncode", [-120, 420], inputs=[("clip", "CLIP")],
                  outputs=[("CONDITIONING", "CONDITIONING")],
                  widgets=["highly detailed architectural photo, sharp"], size=[300,120], title="放大正向")
    neg2 = g.node("CLIPTextEncode", [-120, 560], inputs=[("clip", "CLIP")],
                  outputs=[("CONDITIONING", "CONDITIONING")],
                  widgets=["blurry, artifacts"], size=[300,120], title="放大負向")
    g.link(ckpt, 1, pos2, 0, "CLIP")
    g.link(ckpt, 1, neg2, 0, "CLIP")
    usd = g.node("UltimateSDUpscale", [300, 120],
                 inputs=[("image", "IMAGE"), ("model", "MODEL"), ("positive", "CONDITIONING"),
                         ("negative", "CONDITIONING"), ("vae", "VAE"), ("upscale_model", "UPSCALE_MODEL")],
                 outputs=[("IMAGE", "IMAGE")],
                 widgets=[2, 0, "fixed", 0.18, 20, 7, "dpmpp_2m", "karras",
                          512, 512, 8, 32, "Linear", 1024, 1.0, False, True],
                 size=[320, 520], title="Ultimate SD Upscale x2")
    g.link(dec, 0, usd, 0, "IMAGE")
    g.link(ckpt, 0, usd, 1, "MODEL")
    g.link(pos2, 0, usd, 2, "CONDITIONING")
    g.link(neg2, 0, usd, 3, "CONDITIONING")
    g.link(ckpt, 2, usd, 4, "VAE")
    g.link(upscaler, 0, usd, 5, "UPSCALE_MODEL")

    save_image(g, dec, 0, 300, -200, "Architecture/render")
    save_image(g, usd, 0, 700, 120, "Architecture/render_4k")
    g.save("Architecture", "Architecture_Pro.json")


# ============================================================
#  工作流 2：Interior Design Pro  (SketchUp -> 室內，雙 ControlNet)
# ============================================================
def wf_interior():
    g = Graph()
    img = g.node("LoadImage", [-2200, 300], outputs=[("IMAGE", "IMAGE"), ("MASK", "MASK")],
                 widgets=["sketchup_screenshot.png", "image"], title="SketchUp 截圖")
    depth = g.node("DepthAnythingV2Preprocessor", [-1860, 200],
                   inputs=[("image", "IMAGE")], outputs=[("IMAGE", "IMAGE")],
                   widgets=["depth_anything_v2_vitl.pth", 1024], title="Depth 預處理")
    canny = g.node("CannyEdgePreprocessor", [-1860, 420],
                   inputs=[("image", "IMAGE")], outputs=[("IMAGE", "IMAGE")],
                   widgets=[100, 200, 1024], title="Canny 預處理")
    g.link(img, 0, depth, 0, "IMAGE")
    g.link(img, 0, canny, 0, "IMAGE")

    model, clip, vae = flux_loaders(g, "flux1-kontext-dev.safetensors", x=-2200, y=-360)
    pos = flux_text(g, clip, "photorealistic interior design, cozy modern living room, warm lighting, "
                             "wooden floor, designer furniture, 8k, architectural digest", -1820, -380, 3.5, "正向(室內)")
    neg = flux_text(g, clip, "blurry, distorted perspective, low quality", -1820, -180, 3.5, "負向")

    # 雙 ControlNet：Depth 然後 Canny
    cn_d = g.node("ControlNetLoader", [-1440, 40], outputs=[("CONTROL_NET", "CONTROL_NET")],
                  widgets=["flux_controlnet_union_pro_2.safetensors"], title="ControlNet (Depth)")
    apply_d = g.node("ControlNetApplyAdvanced", [-1200, -120],
                     inputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING"),
                             ("control_net", "CONTROL_NET"), ("image", "IMAGE"), ("vae", "VAE")],
                     outputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING")],
                     widgets=[0.55, 0.0, 0.8], title="套用 Depth")
    g.link(pos, 0, apply_d, 0, "CONDITIONING")
    g.link(neg, 0, apply_d, 1, "CONDITIONING")
    g.link(cn_d, 0, apply_d, 2, "CONTROL_NET")
    g.link(depth, 0, apply_d, 3, "IMAGE")
    g.link(vae, 0, apply_d, 4, "VAE")

    cn_c = g.node("ControlNetLoader", [-1200, 180], outputs=[("CONTROL_NET", "CONTROL_NET")],
                  widgets=["flux_controlnet_union_pro_2.safetensors"], title="ControlNet (Canny)")
    apply_c = g.node("ControlNetApplyAdvanced", [-880, -120],
                     inputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING"),
                             ("control_net", "CONTROL_NET"), ("image", "IMAGE"), ("vae", "VAE")],
                     outputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING")],
                     widgets=[0.45, 0.0, 0.7], title="套用 Canny")
    g.link(apply_d, 0, apply_c, 0, "CONDITIONING")
    g.link(apply_d, 1, apply_c, 1, "CONDITIONING")
    g.link(cn_c, 0, apply_c, 2, "CONTROL_NET")
    g.link(canny, 0, apply_c, 3, "IMAGE")
    g.link(vae, 0, apply_c, 4, "VAE")

    lat = g.node("EmptySD3LatentImage", [-880, 200], outputs=[("LATENT", "LATENT")],
                 widgets=[1536, 1024, 1], title="Latent 1536x1024")
    out = flux_sampler(g, model, apply_c, (lat, 0), steps=24, x=-520, y=-120)
    dec = vae_decode(g, out, vae, -60, -120)
    save_image(g, dec, 0, 320, -120, "Interior/render")
    g.save("Interior", "Interior_Design_Pro.json")


# ============================================================
#  工作流 3：Character Consistency (IPAdapter Face + OpenPose + FaceDetailer)
# ============================================================
def wf_character():
    g = Graph()
    ckpt = g.node("CheckpointLoaderSimple", [-2000, -200],
                  outputs=[("MODEL", "MODEL"), ("CLIP", "CLIP"), ("VAE", "VAE")],
                  widgets=["RealVisXL_V5.0_fp16.safetensors"], title="RealVisXL V5")
    face_img = g.node("LoadImage", [-2000, 200], outputs=[("IMAGE", "IMAGE"), ("MASK", "MASK")],
                      widgets=["face_reference.png", "image"], title="人物參考照")
    pose_img = g.node("LoadImage", [-2000, 560], outputs=[("IMAGE", "IMAGE"), ("MASK", "MASK")],
                      widgets=["pose_reference.png", "image"], title="姿勢參考照")

    # IPAdapter Face
    ipload = g.node("IPAdapterUnifiedLoader", [-1640, -200],
                    inputs=[("model", "MODEL"), ("ipadapter", "IPADAPTER")],
                    outputs=[("model", "MODEL"), ("ipadapter", "IPADAPTER")],
                    widgets=["PLUS FACE (portraits)"], title="IPAdapter 載入(臉)")
    g.link(ckpt, 0, ipload, 0, "MODEL")
    ipapply = g.node("IPAdapterAdvanced", [-1360, -200],
                     inputs=[("model", "MODEL"), ("ipadapter", "IPADAPTER"), ("image", "IMAGE"),
                             ("image_negative", "IMAGE"), ("attn_mask", "MASK"), ("clip_vision", "CLIP_VISION")],
                     outputs=[("MODEL", "MODEL")],
                     widgets=[0.85, "linear", "concat", 0.0, 1.0, "V only"],
                     size=[320, 220], title="IPAdapter 套臉")
    g.link(ipload, 0, ipapply, 0, "MODEL")
    g.link(ipload, 1, ipapply, 1, "IPADAPTER")
    g.link(face_img, 0, ipapply, 2, "IMAGE")

    # OpenPose 預處理 + ControlNet
    openpose = g.node("OpenposePreprocessor", [-1640, 560],
                      inputs=[("image", "IMAGE")], outputs=[("IMAGE", "IMAGE")],
                      widgets=["enable", "enable", "enable", 1024], title="OpenPose 預處理")
    g.link(pose_img, 0, openpose, 0, "IMAGE")
    pos = g.node("CLIPTextEncode", [-1640, -20], inputs=[("clip", "CLIP")],
                 outputs=[("CONDITIONING", "CONDITIONING")],
                 widgets=["a woman in a red dress, standing in a garden, photorealistic, 8k"],
                 size=[340, 130], title="正向(換服裝/背景)")
    neg = g.node("CLIPTextEncode", [-1640, 160], inputs=[("clip", "CLIP")],
                 outputs=[("CONDITIONING", "CONDITIONING")],
                 widgets=["blurry, deformed face, extra fingers, low quality"],
                 size=[340, 110], title="負向")
    g.link(ckpt, 1, pos, 0, "CLIP")
    g.link(ckpt, 1, neg, 0, "CLIP")

    cn = g.node("ControlNetLoader", [-1280, 360], outputs=[("CONTROL_NET", "CONTROL_NET")],
                widgets=["controlnet_union_sdxl_promax.safetensors"], title="ControlNet Union XL")
    cnapply = g.node("ControlNetApplyAdvanced", [-1000, 80],
                     inputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING"),
                             ("control_net", "CONTROL_NET"), ("image", "IMAGE"), ("vae", "VAE")],
                     outputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING")],
                     widgets=[0.7, 0.0, 0.9], title="套用 OpenPose")
    g.link(pos, 0, cnapply, 0, "CONDITIONING")
    g.link(neg, 0, cnapply, 1, "CONDITIONING")
    g.link(cn, 0, cnapply, 2, "CONTROL_NET")
    g.link(openpose, 0, cnapply, 3, "IMAGE")
    g.link(ckpt, 2, cnapply, 4, "VAE")

    lat = g.node("EmptyLatentImage", [-1000, 320], outputs=[("LATENT", "LATENT")],
                 widgets=[1024, 1024, 1], title="Latent 1024")
    ks = g.node("KSampler", [-640, 80],
                inputs=[("model", "MODEL"), ("positive", "CONDITIONING"),
                        ("negative", "CONDITIONING"), ("latent_image", "LATENT")],
                outputs=[("LATENT", "LATENT")],
                widgets=[0, "randomize", 30, 6.0, "dpmpp_2m_sde", "karras", 1.0],
                size=[300, 260], title="KSampler")
    g.link(ipapply, 0, ks, 0, "MODEL")
    g.link(cnapply, 0, ks, 1, "CONDITIONING")
    g.link(cnapply, 1, ks, 2, "CONDITIONING")
    g.link(lat, 0, ks, 3, "LATENT")
    dec = g.node("VAEDecode", [-280, 80], inputs=[("samples", "LATENT"), ("vae", "VAE")],
                 outputs=[("IMAGE", "IMAGE")], title="VAE Decode")
    g.link(ks, 0, dec, 0, "LATENT")
    g.link(ckpt, 2, dec, 1, "VAE")

    # FaceDetailer 精修臉部
    bbox = g.node("UltralyticsDetectorProvider", [-280, 320],
                  outputs=[("BBOX_DETECTOR", "BBOX_DETECTOR"), ("SEGM_DETECTOR", "SEGM_DETECTOR")],
                  widgets=["bbox/face_yolov8m.pt"], title="臉部偵測器")
    fd = g.node("FaceDetailer", [60, 80],
                inputs=[("image", "IMAGE"), ("model", "MODEL"), ("clip", "CLIP"), ("vae", "VAE"),
                        ("positive", "CONDITIONING"), ("negative", "CONDITIONING"),
                        ("bbox_detector", "BBOX_DETECTOR"), ("sam_model_opt", "SAM_MODEL"),
                        ("segm_detector_opt", "SEGM_DETECTOR"), ("detailer_hook", "DETAILER_HOOK")],
                outputs=[("image", "IMAGE"), ("cropped_refined", "IMAGE"),
                         ("cropped_enhanced_alpha", "IMAGE"), ("mask", "MASK"),
                         ("detailer_pipe", "DETAILER_PIPE"), ("cnet_images", "IMAGE")],
                widgets=[768, "bbox", 1024, 0, "randomize", 25, 6.0, "dpmpp_2m_sde", "karras",
                         0.45, 5, True, True, 0.5, 10, 3.0, "center-1", 0, 0.93, 0, 0.7,
                         False, 10, "", 1, False, 20],
                size=[340, 600], title="FaceDetailer 臉部精修")
    g.link(dec, 0, fd, 0, "IMAGE")
    g.link(ipapply, 0, fd, 1, "MODEL")
    g.link(ckpt, 1, fd, 2, "CLIP")
    g.link(ckpt, 2, fd, 3, "VAE")
    g.link(cnapply, 0, fd, 4, "CONDITIONING")
    g.link(cnapply, 1, fd, 5, "CONDITIONING")
    g.link(bbox, 0, fd, 6, "BBOX_DETECTOR")
    save_image(g, fd, 0, 460, 80, "Character/consistent")
    g.save("Character", "Character_Consistency.json")


# ============================================================
#  工作流 4：Product Advertising (IPAdapter + SoftEdge + FLUX Kontext)
# ============================================================
def wf_product():
    g = Graph()
    prod = g.node("LoadImage", [-2000, 300], outputs=[("IMAGE", "IMAGE"), ("MASK", "MASK")],
                  widgets=["product.png", "image"], title="產品照片")
    soft = g.node("HEDPreprocessor", [-1660, 420], inputs=[("image", "IMAGE")],
                  outputs=[("IMAGE", "IMAGE")], widgets=["enable", 1024], title="SoftEdge(HED)預處理")
    g.link(prod, 0, soft, 0, "IMAGE")

    model, clip, vae = flux_loaders(g, "flux1-kontext-dev.safetensors", x=-2000, y=-340)
    # FLUX Kontext 用參考圖編碼 (ReferenceLatent / image conditioning)
    enc = g.node("VAEEncode", [-1660, -40], inputs=[("pixels", "IMAGE"), ("vae", "VAE")],
                 outputs=[("LATENT", "LATENT")], title="參考圖編碼(Kontext)")
    g.link(prod, 0, enc, 0, "IMAGE")
    g.link(vae, 0, enc, 1, "VAE")

    pos = flux_text(g, clip, "premium product advertising photo, the product on a marble podium, "
                             "soft studio lighting, luxury brand aesthetic, bokeh background, 8k", -1640, -360, 3.0, "正向(廣告情境)")
    neg = flux_text(g, clip, "low quality, distorted product, watermark, text", -1640, -160, 3.0, "負向")

    cn = g.node("ControlNetLoader", [-1240, 120], outputs=[("CONTROL_NET", "CONTROL_NET")],
                widgets=["flux_controlnet_union_pro_2.safetensors"], title="FLUX ControlNet (SoftEdge)")
    cnapply = g.node("ControlNetApplyAdvanced", [-1000, -80],
                     inputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING"),
                             ("control_net", "CONTROL_NET"), ("image", "IMAGE"), ("vae", "VAE")],
                     outputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING")],
                     widgets=[0.6, 0.0, 0.8], title="套用 SoftEdge")
    g.link(pos, 0, cnapply, 0, "CONDITIONING")
    g.link(neg, 0, cnapply, 1, "CONDITIONING")
    g.link(cn, 0, cnapply, 2, "CONTROL_NET")
    g.link(soft, 0, cnapply, 3, "IMAGE")
    g.link(vae, 0, cnapply, 4, "VAE")

    out = flux_sampler(g, model, cnapply, (enc, 0), steps=22, x=-600, y=-80, denoise=0.85)
    dec = vae_decode(g, out, vae, -120, -80)

    upscaler = g.node("UpscaleModelLoader", [-120, 160], outputs=[("UPSCALE_MODEL", "UPSCALE_MODEL")],
                      widgets=["4x_foolhardy_Remacri.pth"], title="放大模型")
    up = g.node("ImageUpscaleWithModel", [240, 80],
                inputs=[("upscale_model", "UPSCALE_MODEL"), ("image", "IMAGE")],
                outputs=[("IMAGE", "IMAGE")], title="模型放大 x4")
    g.link(upscaler, 0, up, 0, "UPSCALE_MODEL")
    g.link(dec, 0, up, 1, "IMAGE")
    save_image(g, up, 0, 560, 80, "Product/ad")
    g.save("Product", "Product_Advertising.json")


# ============================================================
#  Wan 2.2 影片共用子圖
# ============================================================
def wan_video_core(g, prompt, neg_prompt, length=81, width=720, height=1280,
                   use_image=True, x=-2000, y=-300):
    """建立 Wan 2.2 I2V/T2V 雙模型(高/低噪)取樣 + 解碼 + 影片輸出。"""
    high = g.node("UNETLoader", [x, y], outputs=[("MODEL", "MODEL")],
                  widgets=["wan2.2_i2v_high_noise_14B_fp16.safetensors" if use_image
                           else "wan2.2_t2v_high_noise_14B_fp16.safetensors", "default"],
                  title="Wan2.2 High-Noise")
    low = g.node("UNETLoader", [x, y+120], outputs=[("MODEL", "MODEL")],
                 widgets=["wan2.2_i2v_low_noise_14B_fp16.safetensors" if use_image
                          else "wan2.2_t2v_low_noise_14B_fp16.safetensors", "default"],
                 title="Wan2.2 Low-Noise")
    clip = g.node("CLIPLoader", [x, y+240], outputs=[("CLIP", "CLIP")],
                  widgets=["umt5_xxl_fp16.safetensors", "wan", "default"], title="UMT5 Text Encoder")
    vae = g.node("VAELoader", [x, y+360], outputs=[("VAE", "VAE")],
                 widgets=["wan_2.1_vae.safetensors"], title="Wan VAE")

    pos = g.node("CLIPTextEncode", [x+360, y], inputs=[("clip", "CLIP")],
                 outputs=[("CONDITIONING", "CONDITIONING")], widgets=[prompt],
                 size=[360, 150], title="正向(動作描述)")
    neg = g.node("CLIPTextEncode", [x+360, y+180], inputs=[("clip", "CLIP")],
                 outputs=[("CONDITIONING", "CONDITIONING")], widgets=[neg_prompt],
                 size=[360, 120], title="負向")
    g.link(clip, 0, pos, 0, "CLIP")
    g.link(clip, 0, neg, 0, "CLIP")

    if use_image:
        img = g.node("LoadImage", [x, y+480], outputs=[("IMAGE", "IMAGE"), ("MASK", "MASK")],
                     widgets=["subject.png", "image"], title="主體照片(寵物/人物)")
        i2v = g.node("WanImageToVideo", [x+760, y],
                     inputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING"),
                             ("vae", "VAE"), ("clip_vision_output", "CLIP_VISION_OUTPUT"),
                             ("start_image", "IMAGE")],
                     outputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING"), ("latent", "LATENT")],
                     widgets=[width, height, length, 1], size=[300, 200], title="WanImageToVideo")
        g.link(pos, 0, i2v, 0, "CONDITIONING")
        g.link(neg, 0, i2v, 1, "CONDITIONING")
        g.link(vae, 0, i2v, 2, "VAE")
        g.link(img, 0, i2v, 4, "IMAGE")
        cond_src = (i2v, 0, 1)   # positive slot0, negative slot1
        lat_src = (i2v, 2)
    else:
        lat = g.node("EmptyHunyuanLatentVideo", [x+760, y+200], outputs=[("LATENT", "LATENT")],
                     widgets=[width, height, length, 1], title="空白影片 Latent")
        cond_src = (pos, 0, None)
        lat_src = (lat, 0)

    # 雙階段取樣：High-noise -> Low-noise
    half = max(2, 0)
    ks_high = g.node("KSamplerAdvanced", [x+1100, y],
                     inputs=[("model", "MODEL"), ("positive", "CONDITIONING"),
                             ("negative", "CONDITIONING"), ("latent_image", "LATENT")],
                     outputs=[("LATENT", "LATENT")],
                     widgets=["enable", 0, "fixed", 20, 3.5, "euler", "simple", 0, 10, "enable"],
                     size=[300, 280], title="KSampler 高噪段")
    g.link(high, 0, ks_high, 0, "MODEL")
    if use_image:
        g.link(cond_src[0], cond_src[1], ks_high, 1, "CONDITIONING")
        g.link(cond_src[0], cond_src[2], ks_high, 2, "CONDITIONING")
    else:
        g.link(pos, 0, ks_high, 1, "CONDITIONING")
        g.link(neg, 0, ks_high, 2, "CONDITIONING")
    g.link(lat_src[0], lat_src[1], ks_high, 3, "LATENT")

    ks_low = g.node("KSamplerAdvanced", [x+1440, y],
                    inputs=[("model", "MODEL"), ("positive", "CONDITIONING"),
                            ("negative", "CONDITIONING"), ("latent_image", "LATENT")],
                    outputs=[("LATENT", "LATENT")],
                    widgets=["disable", 0, "fixed", 20, 3.5, "euler", "simple", 10, 10000, "disable"],
                    size=[300, 280], title="KSampler 低噪段")
    g.link(low, 0, ks_low, 0, "MODEL")
    if use_image:
        g.link(cond_src[0], cond_src[1], ks_low, 1, "CONDITIONING")
        g.link(cond_src[0], cond_src[2], ks_low, 2, "CONDITIONING")
    else:
        g.link(pos, 0, ks_low, 1, "CONDITIONING")
        g.link(neg, 0, ks_low, 2, "CONDITIONING")
    g.link(ks_high, 0, ks_low, 3, "LATENT")

    dec = g.node("VAEDecode", [x+1780, y], inputs=[("samples", "LATENT"), ("vae", "VAE")],
                 outputs=[("IMAGE", "IMAGE")], title="VAE Decode")
    g.link(ks_low, 0, dec, 0, "LATENT")
    g.link(vae, 0, dec, 1, "VAE")
    return dec, vae

def video_combine(g, dec_node, x, y, prefix, fps=16):
    vc = g.node("VHS_VideoCombine", [x, y], inputs=[("images", "IMAGE")],
                outputs=[("Filenames", "VHS_FILENAMES")],
                widgets={"frame_rate": fps, "loop_count": 0, "filename_prefix": prefix,
                         "format": "video/h264-mp4", "pingpong": False, "save_output": True},
                size=[360, 360], title="影片輸出 (mp4)")
    g.link(dec_node, 0, vc, 0, "IMAGE")
    return vc


# ============================================================
#  工作流 5：Animal Video (寵物 I2V)
# ============================================================
def wf_animal_video():
    g = Graph()
    dec, vae = wan_video_core(
        g,
        prompt="a cute parrot dancing and singing, lively motion, natural feathers, "
               "cinematic, high quality",
        neg_prompt="blurry, distorted, deformed, static, low quality",
        length=81, width=720, height=1280, use_image=True)
    video_combine(g, dec, 240, -300, "Video/animal", fps=16)
    g.save("Video", "Animal_Video.json")


# ============================================================
#  工作流 6：Human Video (人物 I2V + FaceDetailer 概念)
# ============================================================
def wf_human_video():
    g = Graph()
    dec, vae = wan_video_core(
        g,
        prompt="a young woman walking and talking, natural body motion, "
               "realistic face, cinematic lighting, high quality",
        neg_prompt="blurry, deformed face, extra limbs, static, low quality",
        length=81, width=720, height=1280, use_image=True)
    video_combine(g, dec, 240, -300, "Video/human", fps=16)
    g.save("Video", "Human_Video.json")


# ============================================================
#  工作流 7：Church Design (教會海報, IPAdapter + FLUX Kontext)
# ============================================================
def wf_church():
    g = Graph()
    ref = g.node("LoadImage", [-2000, 300], outputs=[("IMAGE", "IMAGE"), ("MASK", "MASK")],
                 widgets=["event_photo.png", "image"], title="活動參考照")
    model, clip, vae = flux_loaders(g, "flux1-kontext-dev.safetensors", x=-2000, y=-340)
    enc = g.node("VAEEncode", [-1660, 60], inputs=[("pixels", "IMAGE"), ("vae", "VAE")],
                 outputs=[("LATENT", "LATENT")], title="參考圖編碼")
    g.link(ref, 0, enc, 0, "IMAGE")
    g.link(vae, 0, enc, 1, "VAE")
    pos = flux_text(g, clip,
                    "vibrant church youth event poster, joyful young people, modern graphic design, "
                    "bright colors, bold typography space, summer camp theme, IG post style, 8k",
                    -1640, -360, 3.5, "正向(海報主題)")
    neg = flux_text(g, clip, "low quality, blurry, ugly, distorted text", -1640, -160, 3.5, "負向")

    cn = g.node("ControlNetLoader", [-1240, 120], outputs=[("CONTROL_NET", "CONTROL_NET")],
                widgets=["flux_controlnet_union_pro_2.safetensors"], title="FLUX ControlNet")
    cnapply = g.node("ControlNetApplyAdvanced", [-1000, -80],
                     inputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING"),
                             ("control_net", "CONTROL_NET"), ("image", "IMAGE"), ("vae", "VAE")],
                     outputs=[("positive", "CONDITIONING"), ("negative", "CONDITIONING")],
                     widgets=[0.4, 0.0, 0.6], title="套用 ControlNet")
    g.link(pos, 0, cnapply, 0, "CONDITIONING")
    g.link(neg, 0, cnapply, 1, "CONDITIONING")
    g.link(cn, 0, cnapply, 2, "CONTROL_NET")
    g.link(ref, 0, cnapply, 3, "IMAGE")
    g.link(vae, 0, cnapply, 4, "VAE")

    # 多尺寸輸出：IG貼文 1080x1350 用 1024x1280 latent
    lat = g.node("EmptySD3LatentImage", [-1000, 220], outputs=[("LATENT", "LATENT")],
                 widgets=[1024, 1280, 1], title="Latent (IG 4:5)")
    out = flux_sampler(g, model, cnapply, (lat, 0), steps=24, x=-600, y=-80)
    dec = vae_decode(g, out, vae, -120, -80)
    save_image(g, dec, 0, 300, -80, "Church/poster")
    g.save("Church", "Church_Design.json")


if __name__ == "__main__":
    print("產生工作流 JSON ...")
    wf_architecture()
    wf_interior()
    wf_character()
    wf_product()
    wf_animal_video()
    wf_human_video()
    wf_church()
    print("全部完成。")
