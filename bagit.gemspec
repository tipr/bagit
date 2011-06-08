require 'semver'

BAGIT_SPEC = Gem::Specification.new do |spec|
  spec.name        = "bagit"
  spec.version     = SemVer.find.format '%M.%m.%p'
  spec.summary     = "BagIt package generation and validation"
  spec.description = "Ruby Library and Command Line tools for bagit"
  spec.email       = "flazzarino@gmail.com"
  spec.homepage    = 'http://github.com/flazz/bagit'
  spec.authors     = ["Francesco Lazzarino"]

  spec.add_dependency 'validatable', '~> 1.6'

  spec.files = %w(Rakefile README.md LICENSE.txt bagit.gemspec) + Dir["lib/**/*.rb"]
end
