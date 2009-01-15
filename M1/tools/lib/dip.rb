require 'time'
require 'nokogiri'


class DIP
  
  attr_reader :ieid, :package_id, :create_date
  
  NS = {
    'mets' => 'http://www.loc.gov/METS/',
    'daitss' => 'http://www.fcla.edu/dls/md/daitss/'
  }

  def initialize(path)
    @path = path
    
    # parse the xml descriptor
    doc = open(descriptor) do |io|
      Nokogiri::XML io
    end

    # load the ieid
    ieid_node = doc.xpath('//daitss:IEID', NS).first
    raise "IEID not found" unless ieid_node
    @ieid = ieid_node.content

    # load the package id
    package_id_node = doc.xpath('//daitss:ENTITY_ID', NS).first
    raise "PACAKGE ID not found" unless package_id_node
    @package_id = package_id_node.content

    # load the create date
    create_date_node = doc.xpath('//mets:metsHdr/@CREATEDATE', NS).first
    raise "CREATE DATE not found" unless package_id_node
    @create_date = Time.parse create_date_node.content
  end

  # Return the path the the descriptor, raising errors if not found or
  # multiple posibilities
  def descriptor
    pattern = File.join @path, '*', 'AIP_*_LOC.xml'
    matches = Dir.glob pattern
    raise 'No descriptor found' if matches.empty?
    raise 'Multiple possible descriptors' if matches.size > 1
    matches.first
  end

end

class Representation; end
