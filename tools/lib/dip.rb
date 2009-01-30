# This file contains functionality to extract information from a
# DAITSS DIP for use in constructing a TIPR DIP

require 'nokogiri'
require 'time'

class DIP
  
  attr_reader :rel_path, :ieid, :package_id, :create_date, :original_representation, :current_representation, :migration_map
  
  NS = {
    'mets' => 'http://www.loc.gov/METS/',
    'daitss' => 'http://www.fcla.edu/dls/md/daitss/',
    'xlink' => 'http://www.w3.org/1999/xlink'
  }

  def initialize(path)
    @path = path.chomp('/')     # Strip any trailing /es
    @doc = load_descriptor
    @rel_path = load_rel_path
    @ieid = load_ieid
    @package_id = load_package_id
    @create_date = load_create_date
    @dfid_map = load_dfid_map
    @migration_map = load_migration_map
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
  
  def load_rel_path             # includes package_id
    matches = Dir.glob "#{@path}/*/AIP_*_LOC.xml"
    dir = File.dirname(matches.first)
    dir.split("DIPs/").last
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
  
  def load_dfid_map             # Create a map between non-global DFIDs and FILEIDs
    file_ids = @doc.xpath('//mets:structMap//mets:fptr/@FILEID', NS).map do |file_id_node| 
                 file_id_node.content
               end
    dfid_map = Hash.new
    file_ids.uniq.each do |fid|
      tmd = @doc.xpath("//mets:file[@ID = '#{fid}']", NS).first['ADMID']
      dfid = @doc.xpath("//mets:techMD[@ID = '#{tmd}']//daitss:DFID", NS).first.content
      dfid_map[:"#{dfid}"] = fid 
    end
    dfid_map
  end
  
  def load_migration_map        # Create a map between migrated FILEIDs
    mnodes = @doc.xpath('//daitss:REL_TYPE', NS).select { |n| n.content == 'MIGRATED_TO' }
    return nil if mnodes.empty?	# Don't bother going further  
    migration_map = Hash.new    # Will hold FILEID migration relationships
    
    # Look up our DFIDs in our migration relationships, and add their  
    # corresponding FILEIDs to our migration_map hash.

    mnodes.each do |n|

      # DFIDs
      old_dfid = n.parent.xpath('./daitss:DFID_1', NS).first.content 
      new_dfid = n.parent.xpath('./daitss:DFID_2', NS).first.content 
      
      # FILEIDs
      old_file_id = @dfid_map[:"#{old_dfid}"]
      new_file_id = @dfid_map[:"#{new_dfid}"]

      migration_map[:"#{old_file_id}"] = new_file_id

    end
    
    migration_map

  end
  
  def load_original_representation
    
    id_list = @doc.xpath('//mets:file', NS)
    
    # If we've had a migration, exclude these new files from this representation
    if not @migration_map.nil? 
      id_list = id_list.select { |node| not @migration_map.has_value?(node['ID']) }
    end
    
    id_list.map do |file_node| 
      {
      	:sha_1 => file_node['CHECKSUM'],
      	:path => file_node.xpath('mets:FLocat/@xlink:href', NS).first.content,
      	:aip_id => file_node['ID']
      }
    end

  end

  def load_current_representation
  
    return @original_representation if @migration_map.nil? # Original rep is current
    
    # Exclude older files that we've migrated from this representation
    id_list = @doc.xpath('//mets:file', NS).select do |file_node| 
      not @migration_map.member?(:"#{file_node['ID']}")
    end
    
    id_list.map do |file_node| 
      {
        :sha_1 => file_node['CHECKSUM'],
        :path => file_node.xpath('mets:FLocat/@xlink:href', NS).first.content,
        :aip_id => file_node['ID']
      }
    end
    
  end
  
end
