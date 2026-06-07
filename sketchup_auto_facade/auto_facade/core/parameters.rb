# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'units')

module AutoFacade
  # 參數正規化（normalize）與驗證（validate）。
  # 對應 docs/02 §3（Schema）與 §5.2（驗證規則）。
  #
  # 純資料層，不依賴 SketchUp，方便單元測試（T1–T5）。
  module Parameters
    # length 類欄位：需做單位轉換 + 範圍檢查 [min, max]（單位：inch）。
    LENGTH_FIELDS = {
      elevation_width: { default: 144.0, min: 24.0,  max: 600.0, label: '立面寬度' },
      floor_height:    { default: 144.0, min: 96.0,  max: 240.0, label: '樓層高'   },
      fin_spacing:     { default: 12.0,  min: 2.0,   max: 120.0, label: '鰭片間距' },
      fin_width:       { default: 2.5,   min: 0.25,  max: 24.0,  label: '鰭片寬度' },
      fin_depth:       { default: 10.0,  min: 1.0,   max: 48.0,  label: '鰭片深度' },
      slab_thickness:  { default: 8.0,   min: 4.0,   max: 36.0,  label: '樓板厚'   },
      slab_overhang:   { default: 24.0,  min: 0.0,   max: 60.0,  label: '樓板出挑' },
      # 帷幕牆 (P2)
      panel_width:     { default: 36.0,  min: 12.0,  max: 120.0, label: '玻璃單元寬' },
      mullion_width:   { default: 2.0,   min: 0.5,   max: 12.0,  label: '框料寬'     },
      mullion_depth:   { default: 5.0,   min: 1.0,   max: 24.0,  label: '框料深'     }
    }.freeze

    # count 類欄位：整數，不做單位轉換。
    COUNT_FIELDS = {
      bay_count:   { default: 3,  min: 1, max: 10,  label: '開間數'   },
      floor_count: { default: 3,  min: 1, max: 10,  label: '樓層數'   },
      fin_count:   { default: 13, min: 2, max: 200, label: '鰭片數量' }
    }.freeze

    FIN_LAYOUTS = %w[by_count by_spacing].freeze

    module_function

    # 將原始（UI 來的）參數轉成「內部 inch + 型別正確 + 補預設」的雜湊。
    # raw 內含 :units 指定輸入單位。
    def normalize(raw)
      raw    = symbolize(raw)
      units  = Units.supported?(raw[:units]) ? Units.normalize(raw[:units]) : 'inch'
      result = { units: units }

      LENGTH_FIELDS.each do |key, spec|
        given = raw.key?(key) ? raw[key] : spec[:default]
        # 預設值本身即 inch；UI 傳入值才依 units 轉換。
        result[key] = raw.key?(key) ? Units.to_inch(given, units) : given.to_f
      end

      COUNT_FIELDS.each do |key, spec|
        result[key] = raw.key?(key) ? raw[key].to_i : spec[:default]
      end

      layout = raw[:fin_layout].to_s
      result[:fin_layout]    = FIN_LAYOUTS.include?(layout) ? layout : 'by_count'
      result[:fin_color]     = normalize_hex(raw[:fin_color]) || '#3a3f44'
      result[:glass_color]   = normalize_hex(raw[:glass_color]) || '#bcd8e6'
      result[:glass_opacity] = clamp(raw.key?(:glass_opacity) ? raw[:glass_opacity].to_f : 0.35, 0.05, 1.0)
      result
    end

    # 驗證（在 normalize 之後、建模之前）。回傳錯誤訊息陣列；空陣列表示通過。
    def validate(p)
      errs = []

      LENGTH_FIELDS.each do |key, spec|
        v = p[key].to_f
        if v < spec[:min] || v > spec[:max]
          errs << "#{spec[:label]} 超出允許範圍 #{spec[:min]}–#{spec[:max]}（inch）"
        end
      end

      COUNT_FIELDS.each do |key, spec|
        v = p[key].to_i
        if v < spec[:min] || v > spec[:max]
          errs << "#{spec[:label]} 超出允許範圍 #{spec[:min]}–#{spec[:max]}"
        end
      end

      # V2：by_count 模式鰭片數量至少 2 支
      if p[:fin_layout] == 'by_count' && p[:fin_count].to_i < 2
        errs << '鰭片數量至少 2 支'
      end

      # 推算實際佈局以檢查 V1 / V3（避免重複實作，交由 FinLayout 計算）
      layout = safe_layout(p)
      if layout
        spacing = layout[:spacing]
        # V1：鰭片寬度需小於間距，否則重疊
        if p[:fin_width].to_f >= spacing
          errs << '鰭片寬度需小於間距，否則鰭片會重疊'
        else
          # V3：淨間隙不足（量化「太密」）
          gap = spacing - p[:fin_width].to_f
          errs << '鰭片過密（淨間隙不足 0.5"），建議減少數量或加寬間距' if gap < 0.5
        end
      end

      # 帷幕牆：框料寬需小於玻璃單元寬，否則無玻璃可容
      if p[:mullion_width].to_f >= p[:panel_width].to_f
        errs << '框料寬需小於玻璃單元寬'
      end

      errs
    end

    # ---- helpers ----

    def clamp(value, lo, hi)
      [[value, lo].max, hi].min
    end

    def safe_layout(p)
      require File.join(File.dirname(__FILE__), '..', 'builder', 'fin_layout')
      FinLayout.compute(p)
    rescue StandardError
      nil
    end

    def normalize_hex(value)
      return nil if value.nil?
      s = value.to_s.strip
      s = "##{s}" unless s.start_with?('#')
      s =~ /\A#[0-9a-fA-F]{6}\z/ ? s.downcase : nil
    end

    def symbolize(hash)
      return {} unless hash.is_a?(Hash)
      hash.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
    end
  end
end
