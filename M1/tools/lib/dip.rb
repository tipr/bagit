require 'time'
require 'libxml'


class DIP
    
  INT_ENTITY_XPATH = 'mets:amdSec/mets:techMD/mets:mdWrap/mets:xmlData/daitss:daitss/daitss:INT_ENTITY'
  
  def initialize(path)
    @path = path
    @descriptor_xml_doc = LibXML::XML::Document.file descriptor_file
  end

  # Return the ieid
  def ieid
    select_from_descriptor(INT_ENTITY_XPATH + '/daitss:IEID').content
  end

  # Return the package id
  def package_id
    select_from_descriptor(INT_ENTITY_XPATH + '/daitss:ENTITY_ID').content
  end

  # Return the creation date
  def create_date
    # '//mets:metsHdr/@CREATEDATE' produces a libxml [BUG] Bus Error
    node = select_from_descriptor '//mets:metsHdr[@CREATEDATE]'
    Time.parse node['CREATEDATE']
  end
  
  protected
  
  NS = {
    :mets => 'http://www.loc.gov/METS/',
    :daitss => 'http://www.fcla.edu/dls/md/daitss/'
  }

  # Return the first node that matches the xpath, raising an error if
  # not found
  def select_from_descriptor(xpath)
    node = @descriptor_xml_doc.find_first xpath, NS
    raise "No IEID found at xpath: #{xpath}" unless node
    node
  end

  # Return the path the the descriptor, raising errors if not found or
  # multiple posibilities
  def descriptor_file
    pattern = File.join @path, '*', 'AIP_*_LOC.xml'
    matches = Dir.glob pattern
    raise 'No DIP descriptor found' if matches.size == 0
    raise 'Multiple AIP descriptors' if matches.size > 1
    matches[0]
  end

end

class Representation; end
