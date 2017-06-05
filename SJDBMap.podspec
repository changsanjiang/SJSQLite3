
Pod::Spec.new do |s|
s.name         = "SJDBMap"
s.version      = "1.0.0"
s.summary      = "Automatically create tables based on the model."
s.description  = "https://github.com/changsanjiang/SJDBMap/blob/master/README.md"
s.homepage     = "https://github.com/changsanjiang/SJDBMap"
s.license      = { :type => "MIT", :file => "LICENSE.md" }
s.author       = { "SanJiang" => "changsanjiang@gmail.com" }
s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/changsanjiang/SJDBMap.git", :tag => "v#{s.version}" }

s.source_files  = 'SJDBMap/*.{h,m}'

s.requires_arc = true

s.subspec 'standard' do |ss|
ss.library = 'sqlite3'
ss.source_files = 'SJDBMap/*.{h,m}'
ss.exclude_files = 'SJDBMap/SJDBMap.m'
end


# build the latest stable version of sqlite3
s.subspec 'standalone' do |ss|
ss.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DFMDB_SQLITE_STANDALONE' }
ss.dependency 'sqlite3'
ss.source_files = 'SJDBMap/*.{h,m}'
ss.exclude_files = 'SJDBMap/SJDBMap.m'
end

# build with FTS support and custom FTS tokenizer source files
s.subspec 'standalone-fts' do |ss|
ss.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DFMDB_SQLITE_STANDALONE' }
ss.source_files = 'SJDBMap/*.{h,m}'
ss.exclude_files = 'SJDBMap/SJDBMap.m'
ss.dependency 'sqlite3/fts'
end

# use SQLCipher and enable -DSQLITE_HAS_CODEC flag
s.subspec 'SQLCipher' do |ss|
ss.dependency 'SQLCipher'
ss.source_files = 'SJDBMap/*.{h,m}'
ss.exclude_files = 'SJDBMap/SJDBMap.m'
ss.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DSQLITE_HAS_CODEC -DHAVE_USLEEP=1' }
end
end
