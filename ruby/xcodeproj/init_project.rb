require 'Xcodeproj'
require 'pathname'
require 'yaml'

proj_path = ARGV[0].nil? ? "." : ARGV[0]
Dir.chdir(proj_path)
$project = Xcodeproj::Project.open('Unity-iPhone.xcodeproj')
$products_group = $project.main_group['Products'] || $project.main_group.new_group('Products')
sdk_path = Pathname.new('./SDK').realdirpath.to_s
$sdk_group = $project.main_group['SDK'] || $project.main_group.new_group('SDK', sdk_path, :group)
$default_target = $project.targets.find { |x| x.name == 'Unity-iPhone' }
$common_config = YAML.load(File.open("./Configs/Common.yml"))
lib_path = Pathname.new('./SDK').realdirpath.to_s
$lib_group = $project.main_group['Libraries'] || $project.main_group.new_group('Libraries', lib_path, :group)
$frameworks_group = $project.frameworks_group['iOS'] || $project.frameworks_group.new_group('iOS')

def dup_target(target, name)
  dup = $project.new(Xcodeproj::Project::Object::PBXNativeTarget)
  $project.targets << dup
  dup.name = name
  dup.build_configuration_list = dup_configurations(target.build_configuration_list)
  build_phases = target.build_phases.map { |x| dup_build_phase(x) }
  build_phases.each do |phase|
    dup.build_phases << phase
  end

  # Product
  product = $products_group.new_product_ref_for_target(name, :application)
  dup.product_reference = product
  dup.product_type = target.product_type

  dup
end

def dup_build_phase(build_phase)
  dup = $project.new(build_phase.class)
  return dup if dup.class == Xcodeproj::Project::Object::PBXResourcesBuildPhase
  build_phase.files_references.each do |file_ref|
    dup.add_file_reference(file_ref)
  end
  if dup.class == Xcodeproj::Project::Object::PBXShellScriptBuildPhase
    dup.name = build_phase.name
    dup.input_paths = deep_dup(build_phase.input_paths)
    dup.output_paths = deep_dup(build_phase.output_paths)
    dup.shell_script = build_phase.shell_script
    dup.shell_path = build_phase.shell_path
    dup.show_env_vars_in_log = build_phase.show_env_vars_in_log
  end
  dup
end

def dup_configurations(build_configuration_list)
  dup = $project.new(Xcodeproj::Project::Object::XCConfigurationList)
  dup.default_configuration_is_visible = build_configuration_list.default_configuration_is_visible
  dup.default_configuration_name = build_configuration_list.default_configuration_name
  build_configuration_list.build_configurations.each do |x|
    conf = $project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
    conf.name = x.name
    conf.build_settings = deep_dup(x.build_settings)
    conf.base_configuration_reference = x.base_configuration_reference

    dup.build_configurations << conf
  end
  dup
end

def update_target_from_config(target, config)
  update_plist_file(target, config)
  update_build_configuration(target, config)
  update_dependencies(target, config)
end

def build_file_tree(target, dir, parent_group, create_if_missing, recursive)
  dir_name = File::basename(dir)
  group = parent_group.groups.find { |e| e.path == dir_name }
  group = parent_group.new_group(dir_name, dir, :group) if group.nil?
  new_references = Array.new
  Dir.entries(dir).each do |i|
    next if i.start_with?('.')
    sub_path = dir + '/' + i
    extname = File.extname(sub_path)
    if %w(.framework .a).include?(extname)
      fr = get_file_reference(group, i, create_if_missing)
      target.frameworks_build_phase.add_file_reference(fr, true) unless fr.nil?
      next
    end

    if %w(.bundle .xib .png .xcassets .xcdatamodeld).include?(extname)
      fr = get_file_reference(group, i, create_if_missing)
      target.resources_build_phase.add_file_reference(fr, true) unless fr.nil?
      next
    end

    case File.ftype(sub_path)
      when 'file'
        fr = get_file_reference(group, i, create_if_missing)
        new_references << fr unless fr.nil? || %(.h .plist).include?(extname)
      when 'directory'
        build_file_tree(target, sub_path, group, create_if_missing, recursive) if recursive
    end
  end
  target.add_file_references(new_references)
end

def get_file_reference(group, file, create_if_missing)
  hierarchy_path = group.hierarchy_path + '/' + file
  fr = group.files.find { |x| x.hierarchy_path == hierarchy_path }
  fr = group.new_reference(file, :group) if fr.nil? && create_if_missing
  fr
end

def deep_dup(object)
  case object
  when Hash
    new_hash = {}
    object.each do |key, value|
      new_hash[key] = deep_dup(value)
    end
    new_hash
  when Array
    object.map { |value| deep_dup(value) }
  when TrueClass
    object
  else
    object.dup
  end
end

#添加target配置信息
def update_build_configuration(target, config)
  config['buildConfiguration'].each_key do |i|
    target.build_configuration_list.set_setting(i, config['buildConfiguration'][i])
  end

  return if config == $common_config
  
  debug_cfg = target.build_configuration_list['Debug']
  debug_cfg.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ["DEBUG=1"]

  release_cfg = target.build_configuration_list['Release']
  release_cfg.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = []

  target.build_configuration_list.build_configurations.each do |bc|
    bc.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << %Q|PAY_PLATFORM_#{config['name'].upcase}|
  end
end

#更新plist信息
def update_plist_file(target, config)
  path = Pathname.new("./SDK/#{target.name}").realdirpath.to_s + '/' + "Info.Plist"
  plist = Xcodeproj::Plist::read_from_path(path)
  config['infoPlist'].each do |key, value|
    plist[key] = value
  end
  Xcodeproj::Plist::write_to_path(plist, path)
end

def update_dependencies(target, config)
  return if config['dependencies'].nil?
  files = $frameworks_group.files + $project.frameworks_group.files + $project.main_group.files
  system_frameworks = config['dependencies']['framework']
  unless system_frameworks.nil?
    system_frameworks = system_frameworks.sort
    for i in system_frameworks
      file = files.find { |x|
          next if x.name.nil?
          File.basename(x.path, '.*') == i
      }
      if file.nil?
        target.add_system_framework(i)
      else
        target.frameworks_build_phase.add_file_reference(file, true)
      end
    end
  end
  system_dylib = config['dependencies']['dylib']
  unless system_dylib.nil?
    system_dylib = system_dylib.sort
    for i in system_dylib
      file = files.find { |x|
        next if x.name.nil?
        File.basename(x.name, '.*') == 'lib' + i
      }
      if file.nil?
        target.add_system_library(i)
      else
        target.frameworks_build_phase.add_file_reference(file, true)
      end
    end
  end
end

def update_compiler_flags
  $common_config['arcFlag'].each do |x|
    update_compiler_flags_for_path(x)
  end
end

def update_compiler_flags_for_path(relative_path)
  path = Pathname.new(relative_path).realdirpath.to_s
  extname = File.extname(path)
  case File.ftype(path)
  when 'file'
    return unless %w(.m .mm).include?(extname)
    reference = $project.reference_for_path(path)
    return if reference.nil?
    $project.targets.each do |target|
      build_file = target.source_build_phase.build_file(reference)
      next if build_file.nil?
      build_file.settings = Hash.new if  build_file.settings.nil?
      build_file.settings["COMPILER_FLAGS"] = "-fobjc-arc"
    end
  when 'directory'
    return if %w(xcassets framework bundle).include?(extname)
    dir = Dir.entries(path)
    dir.each do |x|
      next if x.start_with?('.')
      update_compiler_flags_for_path(path + '/' + x)
    end
  end
end

$common_config['targets'].each do |x|
  config = YAML.load(File.open("./Configs/#{x}.yml"))
  next unless config
  target = $project.targets.find { |x| x.name == config['name'] }
  if target.nil?
    target = dup_target($default_target, config['name'])
  end
  puts "update target : #{target.name}"
  build_file_tree(target, Pathname.new(config['source']).realdirpath.to_s, $sdk_group, true, true)
  build_file_tree(target, Pathname.new("./Libraries").realdirpath.to_s, $project.main_group, false, false)
  build_file_tree(target, Pathname.new("./Classes").realdirpath.to_s, $project.main_group, true, true)
  update_target_from_config(target, $common_config)
  update_target_from_config(target, config)
  update_compiler_flags()
end

$project.save
