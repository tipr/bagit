#!/usr/bin/env ruby

require 'libxml'

path = ARGV[0]
$pathToData = 	'mets:amdSec/mets:techMD/mets:mdWrap/mets:xmlData/' +
		'daitss:daitss/daitss:INT_ENTITY'
$mets_ns = 'mets:http://www.loc.gov/METS/'
$daitss_ns = 'daitss:http://www.fcla.edu/dls/md/daitss/'


def findAIP(p)
  # Takes a path and returns a distinct AIP file that matches along that path
  # if it exists, else throws an error
  
  pattern = File.join p,"*","AIP_*_LOC.xml"
  matches = Dir.glob pattern
  raise "No matches, or too many matches" unless matches.size == 1
  d = matches[0]
  raise "Not a regular file" unless File.file? d
  return d
end


def findCreateDate(d)
  # Takes a parsed local AIP xml file and returns the Create Date of the DAITSS package
  nodes = d.find('mets:metsHdr', $mets_ns)
  raise "No metsHdr exists in the AIP, or there are too many" unless nodes.length == 1
  hdr = nodes.first
  return hdr["CREATEDATE"]
  nodes = nil
end

def findIEID(d)
  # Takes a parsed local AIP xml file and returns the IEID of the DAITSS package
  nodes = d.find($pathToData + '/daitss:IEID', $daits_ns)
  puts nodes.length
  raise "IEID does not exist, or too many IEIDs" unless nodes.length == 1
  hdr = nodes.first
  return hdr.content
  nodes = nil
end  

def findEntityID(d)
  # Takes a parsed local AIP xml file and returns the EntityID of the DAITSS package
  nodes = d.find($pathToData + '/daitss:ENTITY_ID', $daitss_ns)
  raise "Entity ID does not exist, or too many Entity IDs" unless nodes.length == 1
  hdr = nodes.first
  return hdr.content
  nodes = nil
end    
  
  
d = findAIP(path)
puts "Descriptor found: #{d}" 

parser = LibXML::XML::Parser.new
parser.file = d
doc = parser.parse

# Print CreateDate, IEID, and EntityID (generally the PackageName)
puts findCreateDate(doc)
puts findIEID(doc)
puts findEntityID(doc)
