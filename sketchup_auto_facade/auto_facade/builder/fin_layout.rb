# frozen_string_literal: true

module AutoFacade
  # 鰭片佈局演算法（docs/02 §5）。
  #
  # 立面寬度 W 固定；鰭片等距分佈於 0..W（端點各一支）。
  # 兩種互斥模式杜絕「數量×間距 ≠ 立面寬」的根本矛盾。
  #
  # 純運算，不依賴 SketchUp。回傳：
  #   { count:, spacing:, xs: [中心 X 座標...] }（單位 inch）
  module FinLayout
    module_function

    def compute(p)
      w = p[:elevation_width].to_f
      raise ArgumentError, '立面寬度需大於 0' if w <= 0

      case p[:fin_layout].to_s
      when 'by_spacing' then by_spacing(p, w)
      else                   by_count(p, w)
      end
    end

    # 模式 A：鎖定數量，推算間距。
    def by_count(p, w)
      n = p[:fin_count].to_i
      raise ArgumentError, '鰭片數量至少 2 支' if n < 2

      spacing = w / (n - 1)
      { count: n, spacing: spacing, xs: positions(n, spacing) }
    end

    # 模式 B：鎖定間距，推算數量（端點貼齊後均分修正）。
    def by_spacing(p, w)
      s = p[:fin_spacing].to_f
      raise ArgumentError, '鰭片間距需大於 0' if s <= 0

      segments = [(w / s).round, 1].max
      n = segments + 1
      actual = w / segments
      { count: n, spacing: actual, xs: positions(n, actual) }
    end

    def positions(n, spacing)
      Array.new(n) { |i| i * spacing }
    end
  end
end
