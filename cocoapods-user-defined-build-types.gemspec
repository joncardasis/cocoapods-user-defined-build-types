# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-user-defined-build-types/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-user-defined-build-types'
  spec.version       = CocoapodsUserDefinedBuildTypes::VERSION
  spec.authors       = ['Jonathan Cardasis']
  spec.email         = ['joncardasis@gmail.com']
  spec.description   = %q{A Cocoapods plugin which selectively modifies a Pod build_type right before integration. This allows for mixing dynamic frameworks with the default static library build type used by Cocoapods.}
  spec.summary       = %q{A Cocoapods plugin which can selectively set build type per pod (static library, dynamic framework, etc.)}
  spec.homepage      = 'https://github.com/joncardasis/cocoapods-user-defined-build-types'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency "cocoapods", ">= 1.5.0", "< 2.0"

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
