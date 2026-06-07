// Auto Facade — 前端邏輯（docs/02 §8）
// 與 Ruby 透過 sketchup.<callback>(json) 與 window.AF.* 回呼通訊。

(function () {
  "use strict";

  var CM_PER_INCH = 2.54;
  var LENGTH_FIELDS = [
    "elevation_width", "floor_height", "fin_spacing",
    "fin_width", "fin_depth", "slab_thickness", "slab_overhang"
  ];
  var COUNT_FIELDS = ["bay_count", "floor_count", "fin_count"];

  var currentUnits = "inch";

  function $(id) { return document.getElementById(id); }
  function val(id) { return parseFloat($(id).value); }
  function radio(name) {
    var el = document.querySelector('input[name="' + name + '"]:checked');
    return el ? el.value : null;
  }

  // 顯示值（目前單位）轉成 inch，供送出 Ruby 前統一。
  // Ruby 端也會再轉一次以保險；此處先以目前單位送出，units 一併附帶。
  function collectParams() {
    var p = {};
    LENGTH_FIELDS.forEach(function (k) { p[k] = val(k); });
    COUNT_FIELDS.forEach(function (k) { p[k] = parseInt($(k).value, 10); });
    p.fin_layout = radio("fin_layout");
    p.fin_color = $("fin_color").value;
    return p;
  }

  // ---- 單位切換：換算所有 length 欄位的顯示值 ----
  function switchUnits(to) {
    if (to === currentUnits) return;
    var factor = (to === "cm") ? CM_PER_INCH : (1 / CM_PER_INCH);
    LENGTH_FIELDS.forEach(function (k) {
      var v = val(k);
      if (!isNaN(v)) $(k).value = round(v * factor, 3);
    });
    document.querySelectorAll(".u").forEach(function (el) { el.textContent = to; });
    currentUnits = to;
    updateHint();
  }

  // ---- 佈局模式：依數量 / 依間距，停用對方欄位 ----
  function applyLayoutMode() {
    var mode = radio("fin_layout");
    $("fin_count").disabled = (mode === "by_spacing");
    $("fin_spacing").disabled = (mode === "by_count");
    updateHint();
  }

  // ---- 前端即時估算（與 Ruby FinLayout 同邏輯，提供即時提示）----
  function estimate() {
    var wInch = toInch(val("elevation_width"));
    var widthInch = toInch(val("fin_width"));
    var mode = radio("fin_layout");
    var count, spacing;

    if (mode === "by_spacing") {
      var s = toInch(val("fin_spacing"));
      if (!(wInch > 0) || !(s > 0)) return null;
      var segments = Math.max(Math.round(wInch / s), 1);
      count = segments + 1;
      spacing = wInch / segments;
    } else {
      count = parseInt($("fin_count").value, 10);
      if (!(wInch > 0) || !(count >= 2)) return null;
      spacing = wInch / (count - 1);
    }
    var gap = spacing - widthInch;
    return { count: count, spacing: spacing, gap: gap };
  }

  function updateHint() {
    var est = estimate();
    var hint = $("hint");
    if (!est) {
      setHint("請輸入有效參數", "");
      return;
    }
    var spacingDisp = round(fromInch(est.spacing), 2);
    if (toInch(val("fin_width")) >= est.spacing) {
      setHint("鰭片寬度 ≥ 間距，將重疊", "error");
    } else if (est.gap < 0.5) {
      setHint("鰭片過密（淨間隙不足 0.5\"）", "error");
    } else {
      setHint(est.count + " 支 · 間距 " + spacingDisp + currentUnits, "ok");
    }
  }

  function setHint(text, cls) {
    var hint = $("hint");
    hint.textContent = text;
    hint.className = "hint" + (cls ? " " + cls : "");
  }

  // ---- 送出生成 ----
  function generate() {
    var payload = JSON.stringify({
      action: "generate",
      units: currentUnits,
      params: collectParams()
    });
    if (window.sketchup && sketchup.generate) {
      sketchup.generate(payload);
    } else {
      console.log("generate payload:", payload);
    }
  }

  // ---- Ruby → JS 回呼 ----
  window.AF = {
    onGenerated: function (res) {
      if (!res.ok) {
        setHint("生成失敗：" + (res.errors || []).join("；"), "error");
        return;
      }
      setHint("已生成 " + res.fin_count + " 支 · 間距 " +
        res.fin_spacing_in + "\" · " + res.floor_count + " 層", "ok");
    },
    onDefaults: function (defaults) {
      // 預留：以 Ruby 預設回填面板（目前 HTML 已內建相同預設）。
    }
  };

  // ---- 工具 ----
  function toInch(v) { return currentUnits === "cm" ? v / CM_PER_INCH : v; }
  function fromInch(v) { return currentUnits === "cm" ? v * CM_PER_INCH : v; }
  function round(v, n) { var f = Math.pow(10, n); return Math.round(v * f) / f; }

  // ---- 綁定 ----
  function init() {
    document.querySelectorAll('input[name="units"]').forEach(function (el) {
      el.addEventListener("change", function () { switchUnits(this.value); });
    });
    document.querySelectorAll('input[name="fin_layout"]').forEach(function (el) {
      el.addEventListener("change", applyLayoutMode);
    });
    ["elevation_width", "fin_count", "fin_spacing", "fin_width"].forEach(function (k) {
      $(k).addEventListener("input", updateHint);
    });
    $("generate").addEventListener("click", generate);

    applyLayoutMode();
    updateHint();
    if (window.sketchup && sketchup.request_defaults) sketchup.request_defaults("");
  }

  document.addEventListener("DOMContentLoaded", init);
})();
