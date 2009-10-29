Gem::Specification.new do |spec|
  spec.name = "bagit"
  spec.version = '0.0.3'
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
end
