is_version_1_9_x = Pod.const_defined?(:BuildType) # CP v1.9.x

# Assign BuildType to proper module definition dependent on CP version.
BuildType = is_version_1_9_x ? Pod::BuildType : Pod::Target::BuildType

module Pod    
  class UserOption

    def self.keyword
      :build_type
    end

    # [Hash{String, BuildType}] mapping of Podfile keyword to a BuildType
    def self.keyword_mapping
      {
        :dynamic_framework => BuildType.dynamic_framework,
        :dynamic_library => BuildType.dynamic_library,
        :static_framework => BuildType.static_framework,
        :static_library => BuildType.static_library
      }
    end
  end
end