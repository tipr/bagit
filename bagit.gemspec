
BAGIT_SPEC = Gem::Specification.new do |spec|
  spec.name        = "bagit"
  spec.version     = '0.3.0.pre'
  spec.summary     = "BagIt package generation and validation"
  spec.description = "Ruby Library and Command Line tools for bagit"
  spec.email       = "johnson.tom@gmail.com"
  spec.homepage    = 'http://github.com/tipr/bagit'
  spec.authors     = ["Tom Johnson, Francesco Lazzarino"]

  spec.add_dependency 'validatable', '~> 1.6'

  spec.files = %w(Rakefile README.md LICENSE.txt bagit.gemspec) + Dir["lib/**/*.rb"]
  spec.executables << 'bagit'
end
