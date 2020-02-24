require_relative 'podfile_options'

module Pod    

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

        CocoapodsUserDefinedBuildTypes.verbose_log("Hooked Cocoapods parse_subspecs function to obtain Pod options. #{pod_name}")

        if options.is_a?(Hash)
          options.each do |k,v|
            next if not options.key?(Pod::UserOption.keyword)
             
            user_build_type = options.delete(k)
            if Pod::UserOption.keyword_mapping.key?(user_build_type)
              build_type = Pod::UserOption.keyword_mapping[user_build_type]
              building_options[pod_name] = build_type
              CocoapodsUserDefinedBuildTypes.verbose_log("#{pod_name} build type set to: #{build_type}")
            else
              raise Pod::Informative, "#{CocoapodsUserDefinedBuildTypes::PLUGIN_NAME} could not parse a #{Pod::UserOption.keyword} of '#{user_build_type}' on #{pod_name}"
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

    # Swizzle 'analyze' cocoapods core function to finalize build settings
    define_method(:analyze) do |analyzer = create_analyzer|
      if !CocoapodsUserDefinedBuildTypes.plugin_enabled
        return swizzled_analyze.bind(self).(analyzer)
      end

      CocoapodsUserDefinedBuildTypes.verbose_log("patching build types...")

      # Run original method
      swizzled_analyze.bind(self).(analyzer)

      # Set user assigned build types on Target objects
      resolve_all_pod_build_types(pod_targets)


      # Update each of @pod_targets private @build_type variable.
      # Note: @aggregate_targets holds a reference to @pod_targets under it's pod_targets variable.
      pod_targets.each do |target|
        next if not target.user_defined_build_type.present?
        
        new_build_type = target.user_defined_build_type
        current_build_type = target.send :build_type

        CocoapodsUserDefinedBuildTypes.verbose_log("#{target.name}: #{current_build_type} ==> #{new_build_type}")
        
        # Override the target's build time for user provided one
        target.instance_variable_set(:@build_type, new_build_type)

        # Verify patching status
        if (target.send :build_type).to_s != new_build_type.to_s
          raise Pod::Informative, "WARNING: Method injection failed on `build_type` of target #{target.name}. Most likely you have a version of cocoapods which is greater than the latest supported by this plugin (#{CocoapodsUserDefinedBuildTypes::LATEST_SUPPORTED_COCOAPODS_VERSION})"
        end
      end
      
      CocoapodsUserDefinedBuildTypes.verbose_log("finished patching user defined build types")
      Pod::UI.puts "#{CocoapodsUserDefinedBuildTypes::PLUGIN_NAME} updated build options"
    end
  end
end