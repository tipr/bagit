require 'nokogiri'
require 'time'

class DIP
  
  attr_reader :ieid, :package_id, :create_date, :original_representation, :current_representation
  
  NS = {
    'mets' => 'http://www.loc.gov/METS/',
    'daitss' => 'http://www.fcla.edu/dls/md/daitss/',
    'xlink' => 'http://www.w3.org/1999/xlink'
  }

  def initialize(path)
    @path = path

    # Find the descriptor
    matches = Dir.glob "#{@path}/*/AIP_*_LOC.xml"
    raise 'No descriptor found' if matches.empty?
    raise 'Multiple possible descriptors' if matches.size > 1
    descriptor = matches.first
    
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

    # load the representations
    @original_representation = doc.xpath('//mets:structMap[@ID="SMR0"]//mets:fptr/@FILEID', NS).map do |file_id_node|
      file_id = file_id_node.content
      file_node = doc.xpath("//mets:file[@ID = '#{file_id}']", NS).first
      {
        :sha_1 => file_node.attributes['CHECKSUM'],
        :path => file_node.xpath('mets:FLocat/@xlink:href', NS).first.content
      }
    end
    
    @current_representation = doc.xpath('//mets:file', NS).map do |file_node|
      {
        :sha_1 => file_node.attributes['CHECKSUM'],
        :path => file_node.xpath('mets:FLocat/@xlink:href', NS).first.content
      }
    end
    
  end

end
