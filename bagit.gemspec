# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bagit/version'

Gem::Specification.new do |spec|
  spec.name        = "bagit"
  spec.version     = BagIt::VERSION
  spec.summary     = "BagIt package generation and validation"
  spec.description = "Ruby Library and Command Line tools for bagit"
  spec.email       = "johnson.tom@gmail.com"
  spec.homepage    = 'http://github.com/tipr/bagit'
  spec.authors     = ["Tom Johnson, Francesco Lazzarino"]
  spec.license     = "MIT"

  spec.add_dependency 'validatable', '~> 1.6'
  spec.add_dependency 'docopt', '~> 0.5.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'byebug'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
