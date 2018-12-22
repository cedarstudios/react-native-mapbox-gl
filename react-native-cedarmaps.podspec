require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name		= "react-native-cedarmaps"
  s.summary		= "React Native Component for CedarMaps"
  s.version		= package['version'][1..-1]
  s.authors		= { "Sina Abadi" => "sina_abadi@hotmail.com", "Saeed Taheri" => "saeed.taheri@gmail.com" }
  s.homepage    	= "https://github.com/cedarstudios/react-native-mapbox-gl#readme"
  s.license     	= "MIT"
  s.platform    	= :ios, "8.0"
  s.source      	= { :git => "https://github.com/cedarstudios/react-native-mapbox-gl.git" }
  s.source_files	= "ios/RCTMGL/**/*.{h,m}"

  s.vendored_frameworks = 'ios/Mapbox.framework'
  s.dependency 'React'
end
