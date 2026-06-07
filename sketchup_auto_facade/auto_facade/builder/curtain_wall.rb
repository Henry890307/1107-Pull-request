# frozen_string_literal: true

base = File.dirname(__FILE__)
require File.join(base, '..', 'core', 'units')
require File.join(base, 'materials')

module AutoFacade
  # 帷幕牆系統 (CW-01 / GL-01)：豎框 + 橫框 + 玻璃單元（P2）。
  #
  # 座標：帷幕面位於 Y=0；框料自 Y=0 向室內(-Y) 出 mullion_depth，
  #       與向室外(+Y) 出挑的鰭片分屬兩側，符合剖面邏輯。
  #
  # 取代 P1 的單一帷幕基準面。
  module CurtainWall
    MULLION_V_DEF = 'AF_MullionV'
    TRANSOM_DEF   = 'AF_Transom'

    module_function

    # 在 parent 群組內建立帷幕牆。回傳統計 { panels:, panel_width: }。
    def build(parent, model, p, total_h)
      grid   = layout(p, total_h)
      group  = add_group(parent, 'CurtainWall')

      mv_def = mullion_v_definition(model, p, total_h)
      tr_def = transom_definition(model, p)

      build_mullions(group, mv_def, grid)
      build_transoms(group, tr_def, grid)
      build_glass(group, model, p, grid)

      { panels: grid[:cols], panel_width: grid[:panel_width].round(3) }
    end

    # 計算格網：垂直線(豎框) X、水平線(橫框) Z。
    def layout(p, total_h)
      w  = p[:elevation_width].to_f
      pw = p[:panel_width].to_f
      cols = [(w / pw).round, 1].max
      actual_pw = w / cols
      x_lines = Array.new(cols + 1) { |i| i * actual_pw }

      z_lines = Array.new(p[:floor_count] + 1) { |f| f * p[:floor_height] }

      { cols: cols, panel_width: actual_pw, x_lines: x_lines,
        z_lines: z_lines, width: w, height: total_h }
    end

    # ---- 構件定義 ----

    # 豎框：mullion_width(X) × mullion_depth(向 -Y) × 全高(Z)
    def mullion_v_definition(model, p, total_h)
      d  = recreate(model, MULLION_V_DEF)
      mw = Units.length(p[:mullion_width])
      md = Units.length(p[:mullion_depth])
      h  = Units.length(total_h)
      f  = d.entities.add_face([0, 0, 0], [mw, 0, 0], [mw, -md, 0], [0, -md, 0])
      f.reverse! if f.normal.z < 0
      f.pushpull(h)
      d
    end

    # 橫框：全寬(X) × mullion_depth(向 -Y) × mullion_width(Z)
    def transom_definition(model, p)
      d  = recreate(model, TRANSOM_DEF)
      w  = Units.length(p[:elevation_width])
      mw = Units.length(p[:mullion_width])
      md = Units.length(p[:mullion_depth])
      f  = d.entities.add_face([0, 0, 0], [w, 0, 0], [w, -md, 0], [0, -md, 0])
      f.reverse! if f.normal.z < 0
      f.pushpull(mw)
      d
    end

    # ---- 構件擺放 ----

    def build_mullions(group, mv_def, grid)
      g = add_group(group, 'Mullions')
      grid[:x_lines].each do |x|
        tr = Geom::Transformation.new([Units.length(x), 0, 0])
        g.entities.add_instance(mv_def, tr)
      end
    end

    def build_transoms(group, tr_def, grid)
      g = add_group(group, 'Transoms')
      grid[:z_lines].each do |z|
        tr = Geom::Transformation.new([0, 0, Units.length(z)])
        g.entities.add_instance(tr_def, tr)
      end
    end

    # 玻璃單元：每個格子一片半透明面，置於框料間（內縮框料半寬）。
    def build_glass(group, model, p, grid)
      g    = add_group(group, 'Glass')
      mat  = Materials.curtain_glass(model, p[:glass_color], p[:glass_opacity])
      mw   = p[:mullion_width]
      y    = -p[:mullion_depth] / 2.0
      cols = grid[:cols]
      zl   = grid[:z_lines]
      xl   = grid[:x_lines]

      (0...cols).each do |c|
        x0 = xl[c] + mw / 2.0
        x1 = xl[c + 1] - mw / 2.0
        next if x1 <= x0
        (0...(zl.length - 1)).each do |r|
          z0 = zl[r] + mw / 2.0
          z1 = zl[r + 1] - mw / 2.0
          next if z1 <= z0
          add_glass_face(g, mat, x0, x1, z0, z1, y)
        end
      end
    end

    def add_glass_face(group, mat, x0, x1, z0, z1, y)
      yy = Units.length(y)
      face = group.entities.add_face(
        [Units.length(x0), yy, Units.length(z0)],
        [Units.length(x1), yy, Units.length(z0)],
        [Units.length(x1), yy, Units.length(z1)],
        [Units.length(x0), yy, Units.length(z1)]
      )
      face.material = mat
      face.back_material = mat
      face
    end

    # ---- helpers ----

    def recreate(model, name)
      old = model.definitions[name]
      model.definitions.remove(old) if old && model.definitions.respond_to?(:remove)
      model.definitions.add(name)
    end

    def add_group(parent, name)
      grp = parent.entities.add_group
      grp.name = name
      grp
    end
  end
end
