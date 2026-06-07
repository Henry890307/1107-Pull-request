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

    # 帷幕基準面：淡藍半透明，暫代玻璃（P2 取代）。
    def curtain_glass(model)
      mat = ensure_material(model, CURTAIN_MATERIAL_NAME)
      mat.color = Sketchup::Color.new(188, 216, 230)
      mat.alpha = 0.35
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
