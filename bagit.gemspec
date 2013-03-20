
BAGIT_SPEC = Gem::Specification.new do |spec|
  spec.name        = "bagit"
  spec.version     = '0.3.0'
  spec.summary     = "BagIt package generation and validation"
  spec.description = "Ruby Library and Command Line tools for bagit"
  spec.email       = "flazzarino@gmail.com"
  spec.homepage    = 'http://github.com/flazz/bagit'
  spec.authors     = ["Francesco Lazzarino"]

  spec.add_dependency 'validatable', '~> 1.6'

  spec.files = %w(Rakefile README.md LICENSE.txt bagit.gemspec) + Dir["lib/**/*.rb"]
end
