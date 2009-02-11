#!/usr/bin/env ruby

# Usage: ./tipr-pack.rb </PATH/TO/DIP> </PATH/TO/TIPR/PACKAGE>
# Note that both /PATH/TO/DIP and /PATH/TO/TIPR/PACKAGE should exist.
# 
# This file creates a bag in a tipr_bag directory inside /PATH/TO/TIPR/PACKAGE
# and populates it with package files and TIPR files generated from the DIP
#
# Note: Currently the entire DIP is copied, but our representations
#       do not reference any "global" xml files. Should the package
#       contain only referenced files?

require 'dip'
require 'tipr'
require 'bagit'
require 'set'
require 'libxml'

dpath = ARGV[0]
tpath = ARGV[1]

# Check arguments
raise "Usage: ./tipr-pack.rb <PATH/TO/DIP> <PATH/TO/TIPR>" if not (dpath && tpath)
raise "<PATH/TO/DIP> (#{ARGV[0]}) should exist" if not File.directory? dpath
raise "<PATH/TO/TIPR> (#{ARGV[1]}) should exist" if not File.directory? tpath

dip = DIP.new dpath                # Our DIP

# need original and active representations and their checksums
orep = TIPR.sha1_pair(TIPR.generate_rep( 'rep.xml.erb', dip, 'ORIG' ))
arep = TIPR.sha1_pair(TIPR.generate_rep( 'rep.xml.erb', dip, 'ACTIVE' ))

# need tipr envelope
tipr = TIPR.generate_tipr_envelope( 'tipr.xml.erb', dip, orep, arep)

# our schemas for validation
mets = LibXML::XML::Schema.new("http://www.loc.gov/standards/mets/mets.xsd")
premis_1 = LibXML::XML::Schema.new("http://www.loc.gov/standards/premis/v1/PREMIS-v1-1.xsd")
#premis = LibXML::XML::Schema.new("http://www.loc.gov/standards/premis/premis.xsd")

# Create our bag
bag_path = File.join(tpath, 'tipr_bag')
tipr_bag = Bagit::Bag.new bag_path

# bag up files from our DIP
Dir.glob("#{dpath}/**/*") do |f|
  if File.file?(f)
  
    # open the file
    my_file = File.open(f, 'r')
    
    # our bag path should *start* with "DIP-PACKAGE-ID" (messy)
    d = "#{dpath}".split('/').last # the "DIP-PACKAGE-ID"
    fp = f.split("#{dpath}").last  # the path relative to "DIP-PACKAGE-ID" 
    my_new_path = File.join(d, fp) # path to use for the bag
    
    tipr_bag.add_file("#{my_new_path}") do |io|
      io.write my_file.read
    end
  end
end

# validate our TIPR envelope, and representations
[orep[:xml], arep[:xml], tipr].each do |xml|
  if TIPR.validate(xml, mets) { |message, flag| puts message }
    puts "validated against mets"
  else
    puts "failed to validate against mets" 
  end
end

# bag our TIPR files
tipr_bag.add_file("rep-1.xml") { |file| file.puts orep[:xml] }
tipr_bag.add_file("rep-2.xml") { |file| file.puts arep[:xml] } if orep != arep
tipr_bag.add_file("tipr.xml") { |file| file.puts tipr }
tipr_bag.add_file("rights.xml") {}
tipr_bag.add_file("digiprov.xml") {}

# generate a list of necessary digiprov files
ofiles = dip.original_representation.map {|n| n[:aip_id]}
afiles = dip.current_representation.map {|n| n[:aip_id]}
fs = ofiles.to_set.union(afiles.to_set)

files = fs.select { |f| not dip.events(f).empty? }

# bag our digiprov files
files.each do |f|
  xml = TIPR.generate_digiprov('digiprov.xml.erb',dip.events(f), 'file')
  
  # bag the file    
  tipr_bag.add_file("digiprov-#{f}.xml") { |file| file.puts xml }
  
  # validate the xml
  if TIPR.validate(xml, premis_1) { |message, flag| puts message }
    puts "digiprov for #{f} validates"
  else
    puts "digiprov for #{f} did not validate" 
  end
   
end

# bag our package digiprov (even if empty)
xml = TIPR.generate_digiprov('digiprov.xml.erb', dip.events_by_oid(dip.ieid), 
                             'representation', dip.ieid)
tipr_bag.add_file("package-digiprov.xml") { |file| file.puts xml } 
if TIPR.validate(xml, premis_1) { |message, flag| puts message }
  puts "package digiprov validates"
else
  puts "package digiprov did not validate"
end




