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
  LATEST_SUPPORTED_COCOAPODS_VERSION = '1.9.1'
  
  @@plugin_enabled = false
  @@verbose_logging = false

  def self.plugin_enabled
    @@plugin_enabled
  end

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

    if Pod::Podfile::DSL.enable_user_defined_build_types
      @@plugin_enabled = true
    else
      Pod::UI.warn "#{PLUGIN_NAME} is installed but the enable_user_defined_build_types! was not found in the Podfile. No build types were changed."
    end
  end
end