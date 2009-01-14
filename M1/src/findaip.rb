#!/usr/bin/env ruby

path=ARGV[0]

pattern = File.join path,"*","AIP_*_LOC.xml"
matches = Dir.glob pattern
raise "No matches, or too many matches" unless matches.size == 1
d = matches[0]
raise "Not a regular file" unless File.file? d

puts "Descriptor found: #{d}" 
