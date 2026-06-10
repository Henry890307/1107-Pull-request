# Templates（共用範本）

這個資料夾放「跨工作流共用」的範本與片段,方便你在建立新工作流時快速組裝。

## 建議放置內容

- **共用載入區**:FLUX 載入組(UNETLoader + DualCLIPLoader + VAELoader)、SDXL Checkpoint 載入組,存成片段重複使用。
- **共用放大區**:Ultimate SD Upscale / ImageUpscaleWithModel 的標準設定。
- **常用 Prompt 範本**:各用途(建築日景/夜景、室內風格、商品情境、教會主題)的正向/負向 prompt 文字檔。
- **解析度預設**:1024×1024、1536×1536、1920×1080、IG 4:5(1024×1280)、IG 限動 9:16、A4。

## 如何把現有工作流存成範本

1. 在 ComfyUI 開啟任一工作流。
2. 框選你想重用的節點 → 右鍵 → **Save Selected as Template**(或 Export)。
3. 匯出的 `.json` 放到本資料夾。
4. 下次用 **Workflow → Open** 或拖入畫布即可重用。

## 共用 Prompt 範本(可直接複製)

```
# 建築-日景(正向)
professional architectural rendering, modern building, daytime, clear blue sky,
photorealistic, ultra detailed, golden hour optional, 8k

# 建築-夜景(正向)
modern building at night, warm interior lights, dramatic exterior lighting,
reflections, cinematic, photorealistic, 8k

# 室內(正向)
photorealistic interior, warm natural light, designer furniture, wooden floor,
cozy modern style, architectural digest, 8k

# 通用負向
blurry, low quality, distorted, deformed, watermark, text, jpeg artifacts
```
