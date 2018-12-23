require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name		= "react-native-mapbox-gl"
  s.summary		= "React Native Component for CedarStudios Mapbox"
  s.version		= package['version']
  s.authors		= { "Sina Abadi" => "sina_abadi@hotmail.com", "Saeed Taheri" => "saeed.taheri@gmail.com" }
  s.homepage    	= "https://github.com/cedarstudios/react-native-mapbox-gl#readme"
  s.license     	= "MIT"
  s.platform    	= :ios, "8.0"
  s.source      	= { :git => "https://github.com/cedarstudios/react-native-mapbox-gl.git" }
  s.source_files	= "ios/RCTMGL/**/*.{h,m}"

  s.dependency 'React'
  s.dependency 'Mapbox-iOS-SDK', '~> 3.7.8'
end
