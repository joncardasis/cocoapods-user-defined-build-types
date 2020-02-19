require_relative 'podfile_options'
require_relative 'utils'

LATEST_SUPPORTED_COCOAPODS_VERSION = '1.8.4'

# //TODO: move this section to private api
module Pod    
  class Prebuild

    # [Hash{String, BuildType}] mapping of Podfile keyword to a BuildType
    def self.keyword_mapping
      {
        :dynamic_framework => Pod::Target::BuildType.dynamic_framework,
        :dynamic_library => Pod::Target::BuildType.dynamic_library,
        :static_framework => Pod::Target::BuildType.static_framework,
        :static_library => Pod::Target::BuildType.static_library
      }
    end
  end

  # TODO: Move to private_api_hooks.rb
  class Podfile
    class TargetDefinition

      # [Hash{String, BuildType}] mapping of pod name to preferred build type if specified.
      @@root_pod_building_options = Hash.new

      def self.root_pod_building_options
        @@root_pod_building_options
      end

      # ======================
      # ==== PATCH METHOD ====
      # ======================
      swizzled_parse_subspecs = instance_method(:parse_subspecs)

      define_method(:parse_subspecs) do |name, requirements|
        # Update hash map of pod target names and association with their preferred linking & packing
        building_options = @@root_pod_building_options
        pod_name = Specification.root_name(name)
        options = requirements.last
        
        Pod::UI.puts "🔥 AWWW YISS MOTHER FUCKING BREADCRUMS. #{pod_name}".green
        # build_type = build_type_for_options(options)
        # Pod::UI.puts "#{pod_name}==== #{build_type}".green

        # if options.is_a?(Hash) && build_type != nil
        #     #should_build_dymanic_framework = options.delete(Pod::Prebuild.keyword) # TODO: use this
        #     building_options[pod_name] = Pod::Target::BuildType.dynamic_framework # TODO: parse options
        #     Pod::UI.puts "cocoapods-use-dynamic-frameworks | #{pod_name} ==> #{Pod::Target::BuildType.dynamic_framework}".green
        #     requirements.pop if options.empty?
        # end

        # NEW
        if options.is_a?(Hash)
          options.each do |k,v|
            if Pod::Prebuild.keyword_mapping.key?(k) && options.delete(k)
              build_type = Pod::Prebuild.keyword_mapping[k]
              puts "#{pod_name} DEFINES CUSTOM VALUE: #{build_type}"
             
              building_options[pod_name] = build_type
              Pod::UI.puts "cocoapods-use-dynamic-frameworks | #{pod_name} ==> #{Pod::Target::BuildType.dynamic_framework}".green
            end
          end
          requirements.pop if options.empty?
        end

        
        # Call old method
        swizzled_parse_subspecs.bind(self).(name, requirements)
      end
      
    end
  end
end

# TODO: Move to private_api_hooks.rb
module Pod
  class Target
    # @return [BuildTarget]
    attr_accessor :user_defined_build_type
  end

  class Installer

    # Walk through pod dependencies and assign build_type from root through all transitive dependencies
    def resolve_all_pod_build_types(pod_targets)
      root_pod_building_options = Pod::Podfile::TargetDefinition.root_pod_building_options.clone

      pod_targets.each do |target|
        next if not root_pod_building_options.key?(target.name)

        build_type = root_pod_building_options[target.name]
        dependencies = target.dependent_targets

        # Cascade build_type down
        while not dependencies.empty?
          new_dependencies = []
          dependencies.each do |dep_target|
            dep_target.user_defined_build_type = build_type
            new_dependencies.push(*dep_target.dependent_targets)
          end
          dependencies = new_dependencies
        end

        target.user_defined_build_type = build_type
      end
    end


    # ======================
    # ==== PATCH METHOD ====
    # ======================

    # Store old method reference
    swizzled_analyze = instance_method(:analyze)

    # Swizzle 'analyze' cocoapods core function
    define_method(:analyze) do |analyzer = create_analyzer|
      Pod::UI.puts "🔥 cocoapods-use-dynamic-frameworks patching linking/packing options".green

      # Run original method
      swizzled_analyze.bind(self).(analyzer)

      # Set user assigned build types on Target objects
      resolve_all_pod_build_types(pod_targets)


      # Update each of @pod_targets private @build_type variable.
      # Note: @aggregate_targets holds a reference to @pod_targets under it's pod_targets variable.
      pod_targets.each do |target|
        next if target.user_defined_build_type == nil
        
        new_build_type = target.user_defined_build_type
        current_build_type = target.send :build_type

        puts "#{target.name}: #{current_build_type} ==> #{new_build_type}"
        
        # Override the target's build time for user provided one
        target.instance_variable_set(:@build_type, new_build_type)

        # Verify patching status
        if (target.send :build_type).to_s != new_build_type.to_s
          raise Pod::Informative, "WARNING: Method injection failed on `build_type` of target #{target.name}. Most likely you have a version of cocoapods which is greater than the latest supported by this plugin (#{LATEST_SUPPORTED_COCOAPODS_VERSION})"
        end
      end
      
      Pod::UI.puts "🔥 cocoapods-use-dynamic-frameworks finished patching".green
    end
  end
end


# public

module Pod 
  class Podfile
    module DSL

      @@use_dynamic_frameworks = false

      def self.use_dynamic_frameworks
        @@use_dynamic_frameworks
      end
      
      def use_dynamic_frameworks! #(root_dynamic_framework_names)
        @@use_dynamic_frameworks = true
        puts 'hit'
      end

    end
  end
end


module CocoapodsSelectiveDynamicFrameworks
  Pod::HooksManager.register('cocoapods-use-dynamic-frameworks', :pre_install) do |installer_context|
    puts 'DYNAMIC: PREHOOK'
    podfile = installer_context.podfile

    use_dynamic_frameworks = Pod::Podfile::DSL.use_dynamic_frameworks
    if use_dynamic_frameworks
      puts '🤩 Do Dynamic stuff'
      #podfile.use_frameworks!
    end

    # Get all dependencies in the Podfile
    all_pods = podfile.dependencies

    #TEST BEGIN
    # puts podfile.methods.sort
    # puts '---'
    # puts installer_context.methods.sort
    # puts '==='

    

    # dependency = all_pods[0]
    # target_definition, dependent_specs = *dependency
    # dependent_specs.group_by(&:root).each do |root_spec, resolver_specs|
    #   all_specs = resolver_specs.map(&:spec)
    #   all_specs_by_type = all_specs.group_by(&:spec_type)
    #   library_specs = all_specs_by_type[:library] || []
    #   test_specs = all_specs_by_type[:test] || []
    #   app_specs = all_specs_by_type[:app] || []
    #   build_type = BuildType.static_library # meat
    #   pod_variant = PodVariant.new(library_specs, test_specs, app_specs, target_definition.platform, build_type)
    #   hash[root_spec] ||= {}
    #   (hash[root_spec][pod_variant] ||= []) << target_definition
    #   pod_variant_spec = hash[root_spec].keys.find { |k| k == pod_variant }
    #   pod_variant_spec.test_specs.concat(test_specs).uniq!
    #   pod_variant_spec.app_specs.concat(app_specs).uniq!
    # end

    #TEST END

    puts installer_context.sandbox
    #sandbox = Pod::Sandbox.new(installer_context.sandbox_root)
    sandbox = installer_context.sandbox


    # project = Xcodeproj::Project.open(sandbox.project_path) #sandbox.project_path
    # project.targets.each do |target|
    #   #config = target.build_configurations.find { |config| config.name.eql? configuration }
    #   puts "⭐️ #{target.name}"
    #   puts target.class
    #   # puts target.build_type

    #   def target.build_type;
    #     Pod::Target::BuildType.static_library
    #   end
    # end
    # project.save

    
    # puts context.pods_project.targets
    # static_installer = Pod::Installer.new(context.sandbox, context.podfile)
    # static_installer.install!

    # unless static_installer.nil?
    #   static_installer.pods_project.targets.each do |target|
    #     # target.build_configurations.each do |config|
    #     #   config.build_settings['CLANG_MODULES_AUTOLINK'] = 'NO'
    #     #   config.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'NO'
    #     # end
    #     puts target.name
    #   end
    #   static_installer.pods_project.save
    # end


    #  pod_targets = installer_context.podfile.root_target_definitions
    #  pod_targets.each do |pod|
    #   puts pod.name
    #  end

    # installer_context.pod_targets.each do |pod|
    #   # if !use_frameworks_pod_names.include?(pod.name)
    #     # def pod.build_type;
    #     #   Pod::Target::BuildType.static_library
    #     # end
    #   # end
    #   puts pod.dynamic_framework
    # end
    
    #pod_names = transitive_dependencies(installer_context.pod_targets, Pod::Podfile::DSL::root_dynamic_framework_names)
    #Pod::UI.puts "some: #{Pod::Podfile::DSL::root_dynamic_framework_names}"
    #Pod::UI.puts "Could not find a target named '#{keys_target}' in your Podfile. Stopping keys".red

    puts "============"
  end
end