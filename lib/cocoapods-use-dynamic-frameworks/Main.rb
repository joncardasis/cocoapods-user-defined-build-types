require_relative 'utils'

module Pod    
  class Podfile
    module DSL
      
      def use_dynamic_frameworks!(root_dynamic_framework_names)
        puts 'hit'
        
        # Default to all pods to dynamic
        use_frameworks!
      end

    end
  end
end


Pod::HooksManager.register('cocoapods-use-dynamic-frameworks', :pre_install) do |installer_context|
  puts 'TEMP TEMP'
  puts installer_context
  
  Pod::UI.puts "some: #{root_dynamic_framework_names}"
end
