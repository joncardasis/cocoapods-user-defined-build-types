require_relative 'podfile_options'
require_relative 'private_api_hooks'

module Pod 
  class Podfile
    module DSL

      @@enable_user_defined_build_types = false

      def self.enable_user_defined_build_types
        @@enable_user_defined_build_types
      end
      
      def enable_user_defined_build_types!
        @@enable_user_defined_build_types = true
      end
    end
  end
end

module CocoapodsUserDefinedBuildTypes
  PLUGIN_NAME = 'cocoapods-user-defined-build-types'
  @@verbose_logging = false

  def self.verbose_logging
    @@verbose_logging
  end

  def self.verbose_log(str)
    if @@verbose_logging || ENV["CP_DEV"]
      Pod::UI.puts "🔥 [#{PLUGIN_NAME}] #{str}".blue
    end
  end

  Pod::HooksManager.register(PLUGIN_NAME, :pre_install) do |installer_context, options|
    if options['verbose'] != nil
      @@verbose_logging = options['verbose']
    end

    if not Pod::Podfile::DSL.enable_user_defined_build_types
      Pod::UI.warn "#{CocoapodsUserDefinedBuildTypes::PLUGIN_NAME} is installed but the enable_user_defined_build_types! was not found in the Podfile. No build types were changed."
      #podfile = installer_context.podfile
      #podfile.use_frameworks!
    end
  end
end