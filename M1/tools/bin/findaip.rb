#!/usr/bin/env ruby

require 'dip'

path = ARGV[0]
dip = DIP.new path

# Print CreateDate, IEID, and EntityID (generally the PackageName)
puts "create date: #{dip.create_date}"
puts "ieid: #{dip.ieid}"
puts "package id: #{dip.package_id}"
