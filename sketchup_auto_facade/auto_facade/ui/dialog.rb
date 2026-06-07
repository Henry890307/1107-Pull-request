# frozen_string_literal: true

require 'json'
base = File.dirname(__FILE__)
require File.join(base, '..', 'builder', 'facade_builder')

module AutoFacade
  # HtmlDialog 面板與 Ruby↔JS 通訊（docs/02 §8）。
  module Dialog
    HTML_DIR = File.join(File.dirname(__FILE__), 'html')

    @dialog = nil

    module_function

    def show
      if @dialog&.visible?
        @dialog.bring_to_front
        return @dialog
      end

      @dialog = build_dialog
      attach_callbacks(@dialog)
      @dialog.set_file(File.join(HTML_DIR, 'index.html'))
      @dialog.show
      @dialog
    end

    def build_dialog
      UI::HtmlDialog.new(
        dialog_title:    "#{PLUGIN_NAME} (P1)",
        preferences_key: 'com.autofacade.p1',
        scrollable:      true,
        resizable:       true,
        width:           360,
        height:          640,
        min_width:       320,
        style:           UI::HtmlDialog::STYLE_DIALOG
      )
    end

    def attach_callbacks(dialog)
      # JS → Ruby：生成 / 更新模型
      dialog.add_action_callback('generate') do |_ctx, json|
        handle_generate(dialog, json)
      end

      # JS → Ruby：取得預設參數（面板初始化）
      dialog.add_action_callback('request_defaults') do |_ctx, _json|
        defaults = Parameters.normalize({})
        dialog.execute_script("AF.onDefaults(#{defaults.to_json})")
      end
    end

    def handle_generate(dialog, json)
      req    = JSON.parse(json, symbolize_names: true) rescue {}
      params = (req[:params] || {}).merge(units: req[:units])
      res    = FacadeBuilder.generate(params)
      dialog.execute_script("AF.onGenerated(#{res.to_json})")
    rescue StandardError => e
      err = { ok: false, errors: ["介面處理失敗：#{e.message}"] }
      dialog.execute_script("AF.onGenerated(#{err.to_json})")
    end
  end
end
