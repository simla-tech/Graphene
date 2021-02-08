source 'https://cdn.cocoapods.org/'

platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

target 'Graphene' do
    pod 'Alamofire', '~> 5.4'
end

target 'GrapheneTests' do
    pod 'Alamofire', '~> 5.4'
end

post_install do |installer|
    installer.pods_project.root_object.attributes['LastSwiftMigration'] = 9999
    installer.pods_project.root_object.attributes['LastSwiftUpdateCheck'] = 9999
    installer.pods_project.root_object.attributes['LastUpgradeCheck'] = 9999
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
        end
    end
end
