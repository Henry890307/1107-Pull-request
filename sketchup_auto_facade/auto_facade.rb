# frozen_string_literal: true

# Auto Facade — SketchUp 建築自動建模外掛（P1：垂直遮陽鰭片立面）
# Extension 載入器：註冊 SketchupExtension，由 SketchUp 的 Extension Manager 管理啟用。
#
# 安裝：將本檔與 auto_facade/ 資料夾一起放入 SketchUp Plugins 目錄，
#       或打包成 .rbz 透過「視窗 > 延伸程式管理器 > 安裝延伸程式」安裝。

require 'sketchup.rb'
require 'extensions.rb'

module AutoFacade
  PLUGIN_NAME    = 'Auto Facade'
  PLUGIN_VERSION = '0.1.0'
  PLUGIN_ID      = 'auto_facade'

  # 本檔所在目錄
  PLUGIN_DIR  = File.dirname(__FILE__).freeze
  # 外掛主程式進入點
  loader_path = File.join(PLUGIN_DIR, PLUGIN_ID, 'main.rb')

  unless defined?(@extension_registered) && @extension_registered
    extension = SketchupExtension.new(PLUGIN_NAME, loader_path)
    extension.version     = PLUGIN_VERSION
    extension.creator     = 'Auto Facade'
    extension.copyright   = '2026'
    extension.description = '參數驅動的建築立面自動建模：垂直遮陽鰭片、樓板與帷幕基準面（P1）。'

    Sketchup.register_extension(extension, true)
    @extension_registered = true
  end
end
