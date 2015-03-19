Pod::Spec.new do |s|
  s.name             = "CLKBlurNavigationController"
  s.version          = "0.2.1"
  s.summary          = "A re-implementation of UIViewController that provides for OS-independent blur behind each screen"
  s.homepage         = "https://github.com/Clinkle/CLKBlurNavigationController"
  s.license          = 'MIT'
  s.author           = { "tsheaff" => "tyler@clinkle.com" }
  s.source           = { :git => "https://github.com/Clinkle/CLKBlurNavigationController.git", :tag => s.version.to_s }

  s.dependency 'CLKParametricAnimations', '~> 0.1.0'
  s.dependency 'FrameAccessor', '~> 1.3.2'
  s.dependency 'FXBlurView', '~> 1.6.3'

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes'
end
