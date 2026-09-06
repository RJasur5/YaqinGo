require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Runner' }
attributes = project.root_object.attributes['TargetAttributes'] || {}
target_attributes = attributes[target.uuid] || {}

target_attributes['SystemCapabilities'] ||= {}
target_attributes['SystemCapabilities']['com.apple.Push'] = { 'enabled' => '1' }
target_attributes['SystemCapabilities']['com.apple.BackgroundModes'] = { 'enabled' => '1' }

attributes[target.uuid] = target_attributes
project.root_object.attributes['TargetAttributes'] = attributes

project.save
puts "Added Push Notifications and Background Modes capabilities to project.pbxproj"
