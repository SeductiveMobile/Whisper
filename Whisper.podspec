Pod::Spec.new do |s|
  s.name             = "Whisper"
  s.summary          = "Whisper is a component that will make the task of display messages and in-app notifications simple."
  s.version          = "6.0.2"
  s.homepage         = "https://github.com/SeductiveMobile/Whisper.git"
  s.license          = 'MIT'
  s.author           = { "Hyper Interaktiv AS" => "ios@hyper.no" }
  s.source           = { :git => "https://github.com/SeductiveMobile/Whisper.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hyperoslo'
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.source_files = 'Source/**/*'
  s.frameworks = 'UIKit', 'Foundation'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
end
