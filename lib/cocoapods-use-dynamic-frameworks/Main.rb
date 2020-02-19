require_relative 'podfile_options'
require_relative 'utils'

LATEST_SUPPORTED_COCOAPODS_VERSION = '1.8.4'

# //TODO: move this section to private api
module Pod    
  class Prebuild
    def self.keyword
        :dynamic_framework
    end
  end

  class Podfile
    class TargetDefinition

      ## --- option for setting using prebuild framework ---
      def parse_prebuild_framework(name, requirements)
          should_prebuild = Pod::Podfile::DSL.prebuild_all

          options = requirements.last
          if options.is_a?(Hash) && options[Pod::Prebuild.keyword] != nil 
              should_prebuild = options.delete(Pod::Prebuild.keyword)
              requirements.pop if options.empty?
          end
  
          pod_name = Specification.root_name(name)
          set_prebuild_for_pod(pod_name, should_prebuild)
      end
      
      def set_prebuild_for_pod(pod_name, should_prebuild)
          
          if should_prebuild == true
              @prebuild_framework_pod_names ||= []
              @prebuild_framework_pod_names.push pod_name
          else
              @should_not_prebuild_framework_pod_names ||= []
              @should_not_prebuild_framework_pod_names.push pod_name
          end
      end

      def prebuild_framework_pod_names
          names = @prebuild_framework_pod_names || []
          if parent != nil and parent.kind_of? TargetDefinition
              names += parent.prebuild_framework_pod_names
          end
          names
      end
      def should_not_prebuild_framework_pod_names
          names = @should_not_prebuild_framework_pod_names || []
          if parent != nil and parent.kind_of? TargetDefinition
              names += parent.should_not_prebuild_framework_pod_names
          end
          names
      end

      # ---- patch method ----
      # We want modify `store_pod` method, but it's hard to insert a line in the 
      # implementation. So we patch a method called in `store_pod`.
      swizzled_parse_inhibit_warnings = instance_method(:parse_inhibit_warnings)

      define_method(:parse_inhibit_warnings) do |name, requirements|
        parse_prebuild_framework(name, requirements)
        old_method.bind(self).(name, requirements)
      end
      
    end
  end
end

# TODO: Move to private_api_hooks.rb
module Pod
  class Installer

    # Hooked attribute to obatain mutable Array<AggregateTarget> data. (As of cocoapods 1.8.4)
    #attr_reader :aggregate_targets

    # Store method reference
    # swizzled_integrate_user_project = instance_method(:integrate_user_project)

    # # Swizzle 'integrate_user_project' cocoapods core function
    # define_method(:integrate_user_project) do
    #   Pod::UI.puts "🔥 cocoapods-use-dynamic-frameworks patching linking/packing options".green
    #   fragile_targets_variable = self.send :aggregate_targets # 'aggregate_targets' is the current variable name (Pod::Installer:aggregate_targets)

    #   fragile_targets_variable.each do |aggregate_target|
    #     aggregate_target.pod_targets.each do |target|

    #       current_build_type = target.send :build_type
    #       #puts "#{current_build_type.class}  ==> #{current_build_type}"
    #       puts "#{target.name} ==> #{current_build_type}"
          

    #       # Override the target's build time for user provided one
    #       target.instance_variable_set(:@build_type, Pod::Target::BuildType.dynamic_framework)
          
    #       # def target.build_type;
    #       #   puts '🌊 awwww yisss'
    #       #   Pod::Target::BuildType.static_library
    #       # end

    #       # def target.build_type;
    #       #   Pod::Target::BuildType.static_library
    #       # end
    #     end
    #   end

    #   #self.instance_variable_set(:@aggregate_targets, fragile_targets_variable)

    #   trueVar = self.instance_variable_get(:@aggregate_targets)
    #   puts trueVar[0].pod_targets[0].send :build_type # expect static_library

    #   # Run original method
    #   swizzled_integrate_user_project.bind(self).()
    # end


    # Store old method reference
    swizzled_analyze = instance_method(:analyze)

    # Swizzle 'analyze' cocoapods core function
    define_method(:analyze) do |analyzer = create_analyzer|
      Pod::UI.puts "🔥 cocoapods-use-dynamic-frameworks patching linking/packing options".green

      # Run original method
      swizzled_analyze.bind(self).()

      # Update each of @pod_targets private @build_type variable.
      # Note: @aggregate_targets holds a reference to @pod_targets under it's pod_targets variable.
      pod_targets.each do |target|
        current_build_type = target.send :build_type
        new_build_type = Pod::Target::BuildType.dynamic_framework # TODO: Map stuff

        #puts "CUSTOM PARAM: #{target.dynamic_framework}"

        puts "#{target.name}: #{current_build_type} ==> #{new_build_type}"
        
        # Override the target's build time for user provided one
        target.instance_variable_set(:@build_type, new_build_type)

        # VERIFY INJECTION SUCCESS. TODO: Cleanup 
        if (target.send :build_type).to_s != new_build_type.to_s
          raise Pod::Informative, "Method injection failed on `build_type` of target #{target.name}. Most likely you have a version of cocoapods which is greater than the latest supported (#{LATEST_SUPPORTED_COCOAPODS_VERSION})"
        end
      end

      puts pod_targets[0].methods.sort
    end

    # class Analyzer
    #   def determine_build_type(spec, target_definition_build_type)
    #     puts "🎃 ATTEMPED HIJACK 2"
    #     Pod::Target::BuildType.static_library
    #   end
    # end
  end

  # class Podfile
  #   class TargetDefinition
  #     def use_frameworks!(option = true)
  #       puts "🎃 ATTEMPED HIJACK on BUILDTYPE"
  #     end
  #   end
  # end 
end


# public

module Pod 
  class Podfile
    module DSL

      @@use_dynamic_frameworks = false
      @@root_dynamic_framework_names = 'valuesss'

      def self.root_dynamic_framework_names
        @@root_dynamic_framework_names
      end

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