require 'xcodeproj'
project_path = 'ImportantDates.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main app target
target = project.targets.find { |t| t.name == 'ImportantDates' }

# Find the source group
# Based on the structure, there is a group named 'ImportantDates' inside the project
source_group = project.main_group['ImportantDates']

if source_group
  files = ['StoreManager.swift', 'PaywallView.swift']
  files.each do |file_name|
    # Check if file is already in the group
    unless source_group.find_file_by_path(file_name)
      file_ref = source_group.new_file(file_name)
      target.add_file_references([file_ref])
      puts "Added #{file_name} to target #{target.name}"
    else
      puts "#{file_name} already exists in project"
    end
  end
else
  puts "Could not find 'ImportantDates' group"
end

# Add StoreKit file as a reference in the root group if not already there
unless project.main_group.find_file_by_path('Pro.storekit')
  project.main_group.new_file('Pro.storekit')
  puts "Added Pro.storekit to project"
end

project.save
puts "Project saved"
