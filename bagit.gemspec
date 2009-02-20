Gem::Specification.new do |spec|
  spec.name = "bagit"
  spec.version = '0.0.1'
  spec.summary = "BagIt package generation and validation"
  spec.email = "flazzarino@gmail.com"
  spec.hompage = 'http://bagit.rubyforge.org'
  spec.authors = ["Francesco (franco) Lazzarino"]
  spec.files = ["Rakefile", "bagit.gemspec",
                "lib/bagit/fetch.rb",
                "lib/bagit/file.rb",
                "lib/bagit/manifest.rb",
                "lib/bagit/packageinfo.rb",
                "lib/bagit/string.rb",
                "lib/bagit.rb"]
  
  spec.has_rdoc = true
  spec.rdoc_options << '--title' << 'Rake -- Ruby Make' <<
                       '--main' << 'README' << '--line-numbers'
end
