# frozen_string_literal: true

module AutoFacade
  # 單位轉換工具。
  #
  # 鐵則（見 docs/02 §3.2）：內部一律以「英吋(inch)」運算與儲存；
  # 單位只影響「顯示與輸入」。count 類（開間/支數/層數）不參與轉換。
  module Units
    CM_PER_INCH = 2.54

    SUPPORTED = %w[inch cm].freeze

    module_function

    # 由顯示單位轉成內部英吋。
    def to_inch(value, from_units)
      v = value.to_f
      case normalize(from_units)
      when 'cm'   then v / CM_PER_INCH
      when 'inch' then v
      else v
      end
    end

    # 由內部英吋轉成顯示單位。
    def from_inch(inch_value, to_units)
      v = inch_value.to_f
      case normalize(to_units)
      when 'cm'   then v * CM_PER_INCH
      when 'inch' then v
      else v
      end
    end

    # 轉成 SketchUp 的 Length 物件（API 內部即英吋）。
    def length(inch_value)
      inch_value.to_f.inch
    end

    def supported?(units)
      SUPPORTED.include?(normalize(units))
    end

    def normalize(units)
      units.to_s.strip.downcase
    end
  end
end
