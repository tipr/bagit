#!/usr/bin/env ruby

# Usage: ./tipr-pack.rb </PATH/TO/DIP> </PATH/TO/TIPR/PACKAGE>
# Note that both /PATH/TO/DIP and /PATH/TO/TIPR/PACKAGE should exist.
# 
# This file creates a tipr-data directory inside /PATH/TO/TIPR/PACKAGE
# and fills it with the necessary files to be bagged.
#
# Note: Currently the entire DIP is copied, but our representations
#       do not reference any "global" xml files. Should the package
#       contain only referenced files?

require 'fileutils'
require 'digest/sha1'
require 'dip'
require 'tipr'

dpath = ARGV[0]
tpath = ARGV[1]

# Check arguments
raise "Usage: ./tipr-pack.rb <PATH/TO/DIP> <PATH/TO/TIPR>" if not (dpath && tpath)
raise "<PATH/TO/DIP> (#{ARGV[0]}) should exist" if not File.directory? dpath
raise "<PATH/TO/TIPR> (#{ARGV[1]}) should exist" if not File.directory? tpath

tipr_data = File.join(tpath, 'tipr-data')# Our data directory
dip = DIP.new dpath			 # Our DIP
orep = TIPR.sha1_pair(			 # Original representation + sha-1
         TIPR.generate_xml( 'rep.xml.erb', dip, 'ORIG' ))
arep = TIPR.sha1_pair(			 # Active representation + sha-1
         TIPR.generate_xml( 'rep.xml.erb', dip, 'ACTIVE' ))


tipr = TIPR.generate_xml( 'tipr.xml.erb', dip, nil, orep, arep) # TIPR envelope

Dir.mkdir(tipr_data)			# Create the Tipr data directory
FileUtils.cp_r(dpath, tipr_data)	# Fill the directory with our DIP files

# Create our TIPR files
File.open("#{tipr_data}/rep-1.xml", 'w') { |file| file.puts orep[:xml] }
File.open("#{tipr_data}/rep-2.xml", 'w') { |file| file.puts arep[:xml] }
File.open("#{tipr_data}/tipr.xml", 'w') { |file| file.puts tipr }
File.open("#{tipr_data}/rights.xml", 'w') {}
File.open("#{tipr_data}/digiprov.xml", 'w') {}


