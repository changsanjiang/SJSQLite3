
Pod::Spec.new do |s|
s.name         = "SJDBMap"
s.version      = "1.0.3"
s.summary      = "Automatically create tables based on the model."
s.description  = "https://github.com/changsanjiang/SJDBMap/blob/master/README.md"
s.homepage     = "https://github.com/changsanjiang/SJDBMap"
s.license      = { :type => "MIT", :file => "LICENSE.md" }
s.author       = { "SanJiang" => "changsanjiang@gmail.com" }
s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/changsanjiang/SJDBMap.git", :tag => "v#{s.version}" }

s.source_files  = 'SJDBMap/*.{h,m}'

s.requires_arc = true

s.ios.library = 'sqlite3'

end
