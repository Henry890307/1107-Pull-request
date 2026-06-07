# frozen_string_literal: true

# 純 Ruby 單元測試（不依賴 SketchUp），對應 docs/02 §10 的 T1–T5。
# 執行：ruby sketchup_auto_facade/test/test_core.rb

require 'minitest/autorun'

base = File.expand_path(File.join(File.dirname(__FILE__), '..', 'auto_facade'))
require File.join(base, 'core', 'units')
require File.join(base, 'core', 'parameters')
require File.join(base, 'builder', 'fin_layout')

class TestUnits < Minitest::Test
  include AutoFacade

  def test_cm_to_inch
    assert_in_delta 1.0, Units.to_inch(2.54, 'cm'), 1e-9
  end

  def test_inch_passthrough
    assert_in_delta 144.0, Units.to_inch(144, 'inch'), 1e-9
  end

  def test_roundtrip
    inch = Units.to_inch(Units.from_inch(10.0, 'cm'), 'cm')
    assert_in_delta 10.0, inch, 1e-9
  end
end

class TestFinLayout < Minitest::Test
  include AutoFacade

  # T1：新版正常 — W=144、13 支、by_count → 間距 12"
  def test_t1_new_version
    p = Parameters.normalize(fin_layout: 'by_count', fin_count: 13, elevation_width: 144)
    layout = FinLayout.compute(p)
    assert_equal 13, layout[:count]
    assert_in_delta 12.0, layout[:spacing], 1e-9
    assert_equal 13, layout[:xs].length
    assert_in_delta 0.0,   layout[:xs].first, 1e-9
    assert_in_delta 144.0, layout[:xs].last,  1e-9
  end

  # T4：by_spacing — W=144、間距 12 → 12 段、13 支、實際間距 12"
  def test_t4_by_spacing
    p = Parameters.normalize(fin_layout: 'by_spacing', fin_spacing: 12, elevation_width: 144)
    layout = FinLayout.compute(p)
    assert_equal 13, layout[:count]
    assert_in_delta 12.0, layout[:spacing], 1e-9
  end

  # T5：單位切換 — 以 cm 輸入 365.76cm(=144in) 應與 T1 等價
  def test_t5_units_equivalence
    p = Parameters.normalize(units: 'cm', fin_layout: 'by_count',
                             fin_count: 13, elevation_width: 365.76)
    layout = FinLayout.compute(p)
    assert_in_delta 12.0, layout[:spacing], 1e-6
  end
end

class TestValidation < Minitest::Test
  include AutoFacade

  # T2：舊版重現 — by_spacing 8" 配窄立面，過密應觸發 V3
  def test_t2_old_version_too_dense
    p = Parameters.normalize(fin_layout: 'by_spacing', fin_spacing: 8,
                             fin_width: 8, elevation_width: 96)
    errs = Parameters.validate(p)
    refute_empty errs
  end

  # T3：溢出 — 間距 8" 但鰭片寬 8" → V1 重疊
  def test_t3_overlap
    p = Parameters.normalize(fin_layout: 'by_count', fin_count: 13,
                             fin_width: 8, elevation_width: 96)
    errs = Parameters.validate(p)
    assert(errs.any? { |e| e.include?('重疊') })
  end

  def test_valid_new_version_passes
    p = Parameters.normalize(fin_layout: 'by_count', fin_count: 13,
                             fin_width: 2.5, elevation_width: 144,
                             fin_depth: 10, slab_thickness: 8, slab_overhang: 24,
                             floor_height: 144, floor_count: 3, bay_count: 3)
    assert_empty Parameters.validate(p)
  end

  def test_out_of_range_count
    p = Parameters.normalize(fin_layout: 'by_count', fin_count: 1)
    errs = Parameters.validate(p)
    refute_empty errs
  end
end
