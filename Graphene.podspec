Pod::Spec.new do |s|
  s.name             = 'Graphene'
  s.version          = '1.0.3'
  s.summary          = "Awesome strongly typed GraphQL client for Swift"
  s.homepage         = 'https://github.com/retailcrm/Graphene'
  s.social_media_url = 'https://retailcrm.pro'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ilya Kharlamov' => 'kharlamov@retailcrm.ru' }
  s.source           = { :git => 'https://github.com/retailcrm/Graphene.git', :tag => s.version.to_s }

  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'

  s.source_files = 'Source/**/*.swift'

  s.dependency 'Alamofire', '~> 5.2'

end
