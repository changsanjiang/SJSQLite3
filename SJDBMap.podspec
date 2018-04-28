
Pod::Spec.new do |s|
s.name         = "SJDBMap"
s.version      = "1.2.0"
s.summary      = "Automatically create tables based on the model."
s.description  = "https://github.com/changsanjiang/SJDBMap/blob/master/README.md"
s.homepage     = "https://github.com/changsanjiang/SJDBMap"
s.license      = { :type => "MIT", :file => "LICENSE.md" }
s.author       = { "SanJiang" => "changsanjiang@gmail.com" }
s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/changsanjiang/SJDBMap.git", :tag => "v#{s.version}" }

s.requires_arc = true
s.ios.library = 'sqlite3'
s.public_header_files  = 'SJDBMap/SJDBMap.h'
s.source_files  = 'SJDBMap/SJDBMap.h'

    s.subspec 'DatabaseMapping' do |ss|
        ss.source_files = 'SJDBMap/DatabaseMapping/*.{h,m}'
        ss.dependency 'SJDBMap/Model'
    end

    s.subspec 'Model' do |ss|
        ss.source_files = 'SJDBMap/Model/*.{h,m}'
        ss.dependency 'SJDBMap/Protocol'
    end

    s.subspec 'Protocol' do |ss|
        ss.source_files = 'SJDBMap/Protocol/*.h'
    end
end
