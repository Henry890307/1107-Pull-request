# frozen_string_literal: true

module AutoFacade
  # 材質套用（docs/02 §7）。依賴 SketchUp API。
  module Materials
    FIN_MATERIAL_NAME     = 'AF_FinColor'
    CURTAIN_MATERIAL_NAME = 'AF_CurtainGlass'

    module_function

    # 將鰭片顏色套到鰭片定義內的所有面。
    def apply_fin_color(model, fin_def, hex)
      mat = ensure_material(model, FIN_MATERIAL_NAME)
      mat.color = hex_to_color(hex)
      mat.alpha = 1.0
      fin_def.entities.grep(Sketchup::Face).each { |f| f.material = mat }
    end

    # 玻璃單元材質：可指定顏色(hex)與透明度(0..1)。
    def curtain_glass(model, hex = '#bcd8e6', opacity = 0.35)
      mat = ensure_material(model, CURTAIN_MATERIAL_NAME)
      mat.color = hex_to_color(hex)
      mat.alpha = opacity.to_f
      mat
    end

    def ensure_material(model, name)
      model.materials[name] || model.materials.add(name)
    end

    # '#3a3f44' → Sketchup::Color
    def hex_to_color(hex)
      s = hex.to_s.sub(/\A#/, '')
      s = '3a3f44' unless s =~ /\A[0-9a-fA-F]{6}\z/
      r = s[0, 2].to_i(16)
      g = s[2, 2].to_i(16)
      b = s[4, 2].to_i(16)
      Sketchup::Color.new(r, g, b)
    end
  end
end
