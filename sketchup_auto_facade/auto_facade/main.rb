# frozen_string_literal: true

# Auto Facade 主程式進入點：建立選單與工具列，由載入器（auto_facade.rb）載入。

base = File.dirname(__FILE__)
require File.join(base, 'core', 'units')
require File.join(base, 'core', 'parameters')
require File.join(base, 'builder', 'fin_layout')
require File.join(base, 'builder', 'materials')
require File.join(base, 'builder', 'facade_builder')
require File.join(base, 'ui', 'dialog')

module AutoFacade
  module Menu
    module_function

    def install
      return if @installed

      menu = UI.menu('Plugins').add_submenu(PLUGIN_NAME)
      menu.add_item('開啟設計面板…') { Dialog.show }
      menu.add_separator
      menu.add_item('以預設參數快速生成') do
        res = FacadeBuilder.generate({})
        UI.messagebox(result_message(res))
      end

      install_toolbar
      @installed = true
    end

    def install_toolbar
      toolbar = UI::Toolbar.new(PLUGIN_NAME)
      cmd = UI::Command.new('Auto Facade') { Dialog.show }
      cmd.tooltip = '開啟 Auto Facade 設計面板'
      cmd.status_bar_text = '參數化生成垂直遮陽鰭片立面'
      toolbar.add_item(cmd)
      toolbar.restore
    rescue StandardError
      # 工具列圖示缺失等非致命錯誤，忽略以免阻擋選單。
      nil
    end

    def result_message(res)
      if res[:ok]
        "已生成 #{res[:fin_count]} 支鰭片，間距 #{res[:fin_spacing_in]}\"，" \
          "#{res[:floor_count]} 層。"
      else
        "無法生成：\n- #{Array(res[:errors]).join("\n- ")}"
      end
    end
  end

  unless defined?(@loaded) && @loaded
    Menu.install
    @loaded = true
  end
end
