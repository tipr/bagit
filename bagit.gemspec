Gem::Specification.new do |spec|
  spec.name = "bagit"
  spec.version = '0.0.2'
  spec.summary = "BagIt package generation and validation"
  spec.email = "flazzarino@gmail.com"
  spec.homepage = 'http://bagit.rubyforge.org'
  spec.authors = ["Francesco Lazzarino"]
  
  spec.files = ["Rakefile", "bagit.gemspec", "lib/bagit/bag.rb",
                "lib/bagit/fetch.rb", "lib/bagit/file.rb",
                "lib/bagit/info.rb", "lib/bagit/manifest.rb",
                "lib/bagit/string.rb", "lib/bagit/valid.rb",
                "lib/bagit.rb" ]
  
  spec.has_rdoc = true
end
