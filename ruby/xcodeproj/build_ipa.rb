require 'xcodeproj'
require 'pathname'
require 'yaml'

proj_path = ARGV[0].nil? ? "." : ARGV[0]
Dir.chdir(proj_path)
$project = Xcodeproj::Project.open('Unity-iPhone.xcodeproj')
$common_config = YAML.load(File.open("./Configs/Common.yml"))

$common_config['targets'].each do |x|
  config = YAML.load(File.open("./Configs/#{x}.yml"))
  next unless config
  target = $project.targets.find { |x| x.name == config['name'] }
  target_name = target.name
  product_name = config['buildConfiguration']['PRODUCT_NAME']
  archive_path = "./Archive/#{target_name}.xcarchive"
  product_path = "#{archive_path}/Release/#{product_name}.app"
  build_time = Time.now
  ipa_path = "./Archive/#{product_name}.ipa"
  profile_name = "zmwy_development_v1"

  puts "start build #{target_name}"

  cmd = "rm -rf #{archive_path}"
  output = `#{cmd}`
  puts output

  cmd = "rm -rf #{ipa_path}"
  output = `#{cmd}`
  puts output

  # clean
  cmd = "xctool -project Unity-iPhone.xcodeproj -scheme #{target_name} -configuration Debug clean"
  output = `#{cmd}`
  puts output
  break unless output.include?("CLEAN SUCCEEDED")

  # # build 
  # cmd = "xctool -project Unity-iPhone.xcodeproj -scheme #{target_name} build"
  # output = `#{cmd}`
  # puts output
  # break unless output.include?("CLEAN SUCCEEDED")

  # archive
  cmd = "xctool -project Unity-iPhone.xcodeproj -scheme #{target_name} -configuration Debug archive -archivePath #{archive_path}"
  output = `#{cmd}`
  puts output
  break unless output.include?("ARCHIVE SUCCEEDED")

  # export
  cmd = "Xcodebuild -exportArchive -archivePath #{archive_path} -exportPath #{ipa_path} -exportFormat ipa -exportProvisioningProfile #{profile_name}"
  output = `#{cmd}`
  puts output
  break unless output.include?("EXPORT SUCCEEDED")
end

puts "build finished"
