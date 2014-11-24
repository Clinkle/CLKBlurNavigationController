Pod::Spec.new do |s|
  s.name             = "CLKBlurNavigationController"
  s.version          = "0.1.0"
  s.summary          = "A re-implementation of UIViewController that provides for OS-independent blur behind each screen"
  s.homepage         = "https://github.com/Clinkle/CLKBlurNavigationController"
  s.license          = 'MIT'
  s.author           = { "tsheaff" => "tyler@clinkle.com" }
  s.source           = { :git => "git://git@github.com/Clinkle/CLKBlurNavigationController.git", :tag => s.version.to_s }

  s.dependency 'FXBlurView', '~> 1.6.3'

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes'
end
