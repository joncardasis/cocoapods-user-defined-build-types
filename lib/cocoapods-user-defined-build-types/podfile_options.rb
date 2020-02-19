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
end