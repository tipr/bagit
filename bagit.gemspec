require 'semver'

Gem::Specification.new do |spec|
  spec.name = "bagit"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "BagIt package generation and validation"
  spec.description = "Ruby Library and Command Line tools for bagit"
  spec.email = "flazzarino@gmail.com"
  spec.homepage = 'http://github.com/flazz/bagit'
  spec.authors = ["Francesco Lazzarino"]

  spec.files = ["Rakefile", "bagit.gemspec", "lib/bagit/bag.rb",
                "lib/bagit/fetch.rb", "lib/bagit/file.rb",
                "lib/bagit/info.rb", "lib/bagit/manifest.rb",
                "lib/bagit/string.rb", "lib/bagit/valid.rb",
                "lib/bagit.rb" ]

  spec.has_rdoc = true
  spec.add_dependency 'semver', '~> 0.1.0'
end
