
Pod::Spec.new do |s|

  s.name         = "SJDBMap"
  s.version      = "1.0.0"
  s.summary      = "Automatically create tables based on the model.."
  s.description  = <<-DESC
                    "https://github.com/changsanjiang/SJDBMap/blob/master/README.md"
                   DESC

  s.homepage     = "https://github.com/changsanjiang/SJDBMap"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "SanJiang" => "changsanjiang@gmail.com" }
  s.platform     = :ios, "8.0"


  s.source       = { :git => "https://github.com/changsanjiang/SJDBMap.git", :tag => "1.0.0" }

  s.source_files  = 'SJDBMapProject', 'SJDBMapProject/SJDBMap/*.{h,m}'


  s.framework  = "UIKit"

  s.requires_arc = true
  s.dependency 'FMDB'

end
