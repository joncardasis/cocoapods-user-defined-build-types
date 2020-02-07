# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-use-dynamic-frameworks/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-use-dynamic-frameworks'
  spec.version       = CocoapodsUseDynamicFrameworks::VERSION
  spec.authors       = ['Jonathan Cardasis']
  spec.email         = ['joncardasis@gmail.com']
  spec.description   = %q{A Cocoapods plugin which selectively enables use_frameworks! per pod.}
  spec.summary       = %q{Cocoapods plugin which selectively enables use_frameworks! per pod. All Cocoapods are bundled into a single dynamic framework, and by default all pods are statically compiled as libraries. Specify specific pods to be compiled as dynamic frameworks.}
  spec.homepage      = 'https://github.com/joncardasis/cocoapods-use-dynamic-frameworks'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency "cocoapods", ">= 1.5.0", "< 2.0"

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
