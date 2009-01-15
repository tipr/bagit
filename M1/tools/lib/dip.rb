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
    @doc = load_descriptor
    @ieid = load_ieid
    @package_id = load_package_id
    @create_date = load_create_date
    @original_representation = load_original_representation
    @current_representation = load_current_representation
  end
  
  protected
  
  def load_descriptor
    matches = Dir.glob "#{@path}/*/AIP_*_LOC.xml"
    raise 'No descriptor found' if matches.empty?
    raise 'Multiple possible descriptors' if matches.size > 1
    descriptor = matches.first
    open(descriptor) { |io| Nokogiri::XML io }
  end

  def load_ieid
    ieid_node = @doc.xpath('//daitss:IEID', NS).first
    raise "IEID not found" unless ieid_node
    ieid_node.content
  end
  
  def load_package_id
    package_id_node = @doc.xpath('//daitss:ENTITY_ID', NS).first
    raise "PACAKGE ID not found" unless package_id_node
    package_id_node.content
  end

  def load_create_date
    create_date_node = @doc.xpath('//mets:metsHdr/@CREATEDATE', NS).first
    raise "CREATE DATE not found" unless create_date_node
    Time.parse create_date_node.content
  end
  
  def load_original_representation
    
    @doc.xpath('//mets:structMap[@ID="SMR0"]//mets:fptr/@FILEID', NS).map do |file_id_node|
      file_id = file_id_node.content
      file_node = @doc.xpath("//mets:file[@ID = '#{file_id}']", NS).first
      
      {
        :sha_1 => file_node.attributes['CHECKSUM'],
        :path => file_node.xpath('mets:FLocat/@xlink:href', NS).first.content
      }
      
    end
    
  end

  def load_current_representation
    
    @doc.xpath('//mets:file', NS).map do |file_node|
      {
        :sha_1 => file_node.attributes['CHECKSUM'],
        :path => file_node.xpath('mets:FLocat/@xlink:href', NS).first.content
      }
    end
    
  end
  
end
