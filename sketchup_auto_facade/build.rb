# frozen_string_literal: true

# 將外掛打包成 SketchUp 可安裝的 .rbz（本質為 zip）。
# 執行：ruby build.rb  → 產生 AutoFacade.rbz
#
# .rbz 內容需包含：auto_facade.rb（載入器）與 auto_facade/ 整個資料夾。

require 'fileutils'

ROOT    = File.dirname(File.expand_path(__FILE__))
OUTPUT  = File.join(ROOT, 'AutoFacade.rbz')
ENTRIES = ['auto_facade.rb', 'auto_facade'].freeze

FileUtils.rm_f(OUTPUT)

Dir.chdir(ROOT) do
  # 排除測試與打包腳本本身；只收錄外掛執行所需檔案。
  if system('which zip > /dev/null 2>&1')
    system('zip', '-r', '-X', OUTPUT, *ENTRIES,
           '-x', '*/.*') or abort('打包失敗（zip）')
  else
    # 後備：用 Ruby 內建 zip（需 rubygems 'rubyzip'）；否則提示改用系統 zip。
    begin
      require 'zip'
    rescue LoadError
      abort('找不到 zip 指令，且未安裝 rubyzip。請安裝其一後重試。')
    end
    Zip::File.open(OUTPUT, Zip::File::CREATE) do |zip|
      ENTRIES.each do |entry|
        if File.directory?(entry)
          Dir.glob(File.join(entry, '**', '**')).each do |f|
            zip.add(f, f) unless File.directory?(f)
          end
        else
          zip.add(entry, entry)
        end
      end
    end
  end
end

puts "已產生：#{OUTPUT}"
