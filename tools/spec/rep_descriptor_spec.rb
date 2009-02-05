require 'erb'
require 'nokogiri'
require 'dip'
require 'tipr'
require 'spec_helper'
require 'all_tipr_files_spec'

share_examples_for "all representations" do

  before(:each) do

    # need a daitss DIP
    path = File.join '..', 'DIPs', 'FDA0666002'
    @dip = DIP.new path

    # need the rep.xml template
    raw_xml = TIPR.generate_xml('rep.xml.erb', @dip, @type)
    @doc = Nokogiri::XML raw_xml   

    # some additional instance variables to help clean up the code 
    @rchildren = @doc.root.children.select { |child| child.name != 'text'}
    @divs = @doc.root.xpath('//mets:structMap/mets:div', NS_MAP)
    @files = @doc.root.xpath('//mets:fileSec//mets:file', NS_MAP)
    @digiprov = @doc.root.xpath('//mets:amdSec/mets:digiprovMD', NS_MAP)
  end

  it_should_behave_like AllTiprFiles
  
  it "should have an amdSec" do
    @doc.root.should have_xpath('//mets:amdSec')
  end
  
  describe "the amdSec" do

    it "should have one digiprov pertaining to the entire package" do
      @doc.root.should have_xpath("//mets:amdSec/mets:digiprovMD[@ID='package-digiprov']")
    end
    
    describe "each digiprov" do
      it "should reference an xml file" do
        @digiprov.each do |dp|
          dp.xpath('mets:mdRef', NS_MAP).first.should reference_an_xml_file
        end
      end
      
      it "should have an MDTYPE of PREMIS" do
        @digiprov.each do |dp|
          dp.should have_xpath("mets:mdRef[@MDTYPE='PREMIS']")
        end
      end
      
    end

  end

  it "should have a fileSec" do
    @doc.should have_xpath('//mets:fileSec')
  end
  
  describe "the fileSec" do

    it "should point to representation descriptors" do
      # Validate each file representation descriptor.
      @files.each do |f|
        f['ID'].should_not be_nil
        f['CHECKSUM'].should_not be_nil
        f['CHECKSUMTYPE'].should eql('SHA-1')
        f.xpath('./mets:FLocat', NS_MAP).first.should reference_a_file      
      end    
    end

    it "should reference digiprovs for files in the fileSec with digiprov information" do
          
      # First grab the representation we want to compare.
      rep = @type.eql?('ORIG') ? @dip.original_representation : @dip.current_representation
      
      # Our indices should be the same as in the xml
      rep.each_with_index do |r, i|
        
        # If there are dip events, there should be an ADMID for this entry and
        # a related digiprov
        if not @dip.events(r[:aip_id]).empty?
          @doc.should have_xpath("//mets:fileSec//mets:file[@ADMID='digiprov-metadata-#{i}']")
          @doc.should have_xpath("//mets:amdSec/mets:digiprovMD[@ID='digiprov-metadata-#{i}']")
        end
      
      end  
          
    end

  end
  
  describe "the struct map" do
    it "should have a file pointer for each file in the filesec" do
      fptrs = @divs.xpath('./mets:fptr', NS_MAP).map { |fp| fp['FILEID'] }
      @files.each { |f| fptrs.should include(f['ID']) }
    end
  end
end


describe "the original representation" do
  before(:each) do
    # this is the original representation
    @type = 'ORIG'
  end

  it_should_behave_like "all representations"  
end


describe "the active representation" do
  before(:each) do
    # this is the active representation
    @type = 'ACTIVE'
  end
  
  it_should_behave_like "all representations"
end
