require 'libxml'

NS_MAP = {
  :mets => 'http://www.loc.gov/METS/',
  :daitss => 'http://www.fcla.edu/dls/md/daitss/'
}

class DIP

  def initialize(path)
    @path = path
  end

  # Return the ieid of this DIP
  def ieid
    doc = LibXML::XML::Document.file descriptor_file
    xpath = 'mets:amdSec/mets:techMD/mets:mdWrap/mets:xmlData/daitss:daitss/daitss:INT_ENTITY/daitss:IEID'
    ieid_node = doc.find_first xpath, NS_MAP
    raise "No IEID found at xpath: #{xpath}" unless ieid_node
    ieid_node.content
  end
  
  protected

  # Return the path the the descriptor of this DIP
  def descriptor_file
    pattern = File.join @path, '*', 'AIP_*_LOC.xml'
    matches = Dir.glob pattern
    raise 'No DIP descriptor found' if matches.size == 0
    raise 'Multiple AIP descriptors' if matches.size > 1
    matches[0]
  end
  
end

class Representation; end
