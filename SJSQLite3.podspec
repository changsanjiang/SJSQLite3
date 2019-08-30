#
# Be sure to run `pod lib lint SJSQLite3.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SJSQLite3'
  s.version          = '1.0.1'
  s.summary          = '模型-表映射.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
模型-表映射. 根据模型自动创建或更新与该类相关的表(多个表), 可以进行增删改查.
                       DESC

  s.homepage         = 'https://github.com/changsanjiang/SJSQLite3'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'changsanjiang@gmail.com' => 'changsanjiang@gmail.com' }
  s.source           = { :git => 'https://github.com/changsanjiang/SJSQLite3.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.default_subspec = 'lib/YYModel'
  s.subspec 'Protocol' do |ss|
      ss.source_files = 'SJSQLite3/Protocol/**/*.{h,m}'
  end
  
  s.subspec 'Core' do |ss|
      ss.source_files = 'SJSQLite3/Core/**/*.{h,m}'
      ss.dependency 'SJSQLite3/Protocol'
  end
  
  s.subspec 'lib' do |ss|
      ss.dependency 'SJSQLite3/Core'
      ss.subspec 'YYModel' do |sss|
          sss.dependency 'YYModel'
      end
      ss.subspec 'YYKit' do |sss|
          sss.dependency 'YYKit'
      end
  end
end
