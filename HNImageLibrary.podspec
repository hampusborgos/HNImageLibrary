Pod::Spec.new do |s|
  s.name         = "HNImageLibrary"
  s.version      = "0.1.0"
  s.summary      = "An simple image library that stores UIImages in a persistent way with caching."
  s.homepage     = "https://github.com/hjnilsson/HNImageLibrary"

  s.license      = { :type => 'MIT', :file => 'MIT-LICENSE' }

  s.author       = { "Hampus Joakim Nilsson" => "mail@hjnilsson.com" }
  s.source       = { :git => "https://github.com/hjnilsson/HNImageLibrary.git", :tag => "0.1.0" }

  s.platform     = :ios, '5.0'

  s.source_files = 'Classes', 'Classes/**/*.{h,m}'
  s.exclude_files = 'Classes/Exclude'

  s.requires_arc = true
end
