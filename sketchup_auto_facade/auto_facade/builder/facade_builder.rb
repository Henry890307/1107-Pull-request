# frozen_string_literal: true

base = File.dirname(__FILE__)
require File.join(base, '..', 'core', 'parameters')
require File.join(base, '..', 'core', 'units')
require File.join(base, 'fin_layout')
require File.join(base, 'curtain_wall')
require File.join(base, 'materials')

module AutoFacade
  # 建模引擎主流程（docs/02 §4、§6）。
  #
  # 座標系：X=立面寬、Y=出挑深、Z=樓高；原點=立面左下角、帷幕基準面(Y=0)。
  # 所有產出包進標記 generated=true 的 [AutoFacade] 頂層群組，
  # 重建只清空此群組，絕不動使用者其他物件；全程單步 Undo。
  module FacadeBuilder
    ROOT_DICT      = 'AutoFacade'
    ROOT_NAME      = 'AutoFacade'
    FIN_DEF_NAME   = 'AF_FinDef'
    SLAB_DEF_NAME  = 'AF_SlabDef'
    SCHEMA_VERSION = 1

    module_function

    # 主入口。raw_params 含 :units。回傳結果雜湊（供 UI 顯示）。
    def generate(raw_params, model = Sketchup.active_model)
      p    = Parameters.normalize(raw_params)
      errs = Parameters.validate(p)
      return { ok: false, errors: errs } unless errs.empty?

      layout  = FinLayout.compute(p)
      total_h = p[:floor_height] * p[:floor_count]

      model.start_operation('Generate Auto Facade', true)
      begin
        root = find_or_create_root(model)
        clear_root(root)

        fin_def  = build_fin_definition(model, p, total_h)
        slab_def = build_slab_definition(model, p)

        build_floors(root, slab_def, p)
        build_fins(root, fin_def, layout, p)
        cw = CurtainWall.build(root, model, p, total_h)

        Materials.apply_fin_color(model, fin_def, p[:fin_color])
        tag_root(root, p, layout)

        model.commit_operation
      rescue StandardError => e
        model.abort_operation
        return { ok: false, errors: ["建模失敗：#{e.message}"] }
      end

      {
        ok: true,
        fin_count: layout[:count],
        fin_spacing_in: layout[:spacing].round(3),
        floor_count: p[:floor_count],
        panels: cw[:panels],
        panel_width_in: cw[:panel_width]
      }
    end

    # ---- 構件樹 ----

    def find_or_create_root(model)
      existing = model.entities.grep(Sketchup::Group).find do |g|
        g.valid? && g.get_attribute(ROOT_DICT, 'generated') == true
      end
      return existing if existing

      g = model.entities.add_group
      g.name = ROOT_NAME
      g.set_attribute(ROOT_DICT, 'generated', true)
      g
    end

    def clear_root(root)
      root.entities.to_a.each { |e| e.erase! if e.valid? }
    end

    def tag_root(root, p, layout)
      root.set_attribute(ROOT_DICT, 'generated', true)
      root.set_attribute(ROOT_DICT, 'schema_version', SCHEMA_VERSION)
      root.set_attribute(ROOT_DICT, 'fin_count', layout[:count])
      root.set_attribute(ROOT_DICT, 'units', p[:units])
    end

    # ---- 構件定義 ----

    # 單一鰭片：底面 fin_width(X) × fin_depth(Y)，沿 +Z 擠出整高。
    def build_fin_definition(model, p, total_h)
      d = recreate_definition(model, FIN_DEF_NAME)
      w   = Units.length(p[:fin_width])
      dep = Units.length(p[:fin_depth])
      h   = Units.length(total_h)
      face = d.entities.add_face(
        [0, 0, 0], [w, 0, 0], [w, dep, 0], [0, dep, 0]
      )
      face.reverse! if face.normal.z < 0
      face.pushpull(h)
      d
    end

    # 樓板：寬 = 立面寬 + 兩側出挑；板厚向下。
    def build_slab_definition(model, p)
      d = recreate_definition(model, SLAB_DEF_NAME)
      w   = Units.length(p[:elevation_width] + 2 * p[:slab_overhang])
      dep = Units.length(p[:fin_depth] + p[:slab_overhang])
      t   = Units.length(p[:slab_thickness])
      face = d.entities.add_face(
        [0, 0, 0], [w, 0, 0], [w, dep, 0], [0, dep, 0]
      )
      face.reverse! if face.normal.z < 0
      face.pushpull(-t)
      d
    end

    def recreate_definition(model, name)
      old = model.definitions[name]
      model.definitions.remove(old) if old && model.definitions.respond_to?(:remove)
      model.definitions.add(name)
    end

    # ---- 構件擺放 ----

    def build_floors(root, slab_def, p)
      floors = add_named_group(root, 'Floors')
      oh = p[:slab_overhang]
      p[:floor_count].times do |f|
        z  = f * p[:floor_height]
        tr = Geom::Transformation.new(
          [Units.length(-oh), Units.length(-oh), Units.length(z)]
        )
        floors.entities.add_instance(slab_def, tr)
      end
      floors
    end

    def build_fins(root, fin_def, layout, p)
      fins  = add_named_group(root, 'Fins')
      halfw = p[:fin_width] / 2.0
      layout[:xs].each do |x|
        tr = Geom::Transformation.new([Units.length(x - halfw), 0, 0])
        fins.entities.add_instance(fin_def, tr)
      end
      fins
    end

    def add_named_group(parent, name)
      g = parent.entities.add_group
      g.name = name
      g
    end
  end
end
