require 'libxml'

DAITSS_NS = 'daitss:http://www.fcla.edu/dls/md/daitss/'

class DIP
  
  def initialize(path)
    @path = path
  end

  # Taken from findIEID
  def ieid
    descriptor = load_descriptor
    
    pathToData = 'mets:amdSec/mets:techMD/mets:mdWrap/mets:xmlData/' +
      'daitss:daitss/daitss:INT_ENTITY'

    nodes = descriptor.find(pathToData + '/daitss:IEID', DAITSS_NS)
    puts nodes.length
    raise "IEID does not exist, or too many IEIDs" unless nodes.length == 1
    hdr = nodes.first
    return hdr.content
    nodes = nil
  end
  
  # Taken from findAip
  def load_descriptor
    pattern = File.join @path,"*","AIP_*_LOC.xml"
    matches = Dir.glob pattern
    raise "No matches, or too many matches" unless matches.size == 1
    d = matches[0]
    raise "Not a regular file" unless File.file? d

    parser = LibXML::XML::Parser.new
    parser.file = d
    doc = parser.parse

    return doc
  end
  
end

class Representation; end
