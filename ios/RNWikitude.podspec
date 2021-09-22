
Pod::Spec.new do |s|
  s.name         = "RNWikitude"
  s.version      = "1.0.0"
  s.summary      = "RNWikitude"
  s.description  = <<-DESC
                  RNWikitude
                   DESC
  s.homepage     = "http://example.com"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/author/RNWikitude.git", :tag => "master" }
  s.vendored_frameworks = 'WikitudeSDK.framework'
  s.source_files  = "*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end
