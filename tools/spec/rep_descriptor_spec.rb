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
    @xmlns = { 'xmlns' => 'http://www.loc.gov/METS/' }  
    @rchildren = @doc.root.children.select { |child| child.name != 'text'}
    @divs = @doc.root.xpath('//xmlns:structMap/xmlns:div', @xmlns)
    @files = @doc.root.xpath('//xmlns:fileSec//xmlns:file', @xmlns)
    @digiprov = @doc.root.xpath('//xmlns:amdSec/xmlns:digiprovMD', @xmlns)
  end

  it_should_behave_like AllTiprFiles
  
  it "should have an amdSec" do
    @doc.root.should have_xpath('//xmlns:amdSec', @xmlns)
  end
  
  describe "the amdSec" do

    it "should have at least as many digiprovs as files in the fileSec" do
      @digiprov.length.should >= @files.length
    end

    it "should have one digiprov pertaining to the entire package" do
      @doc.root.should 
        have_xpath("//xmlns:amdSec/xmlns:digiprovMD[@ID='package-digiprov']", @xmlns)
    end
    
    describe "each digiprov" do
      it "should reference an xml file" do
        @digiprov.each do |dp|
          dp.xpath('./xmlns:mdRef', @xmlns).first.should reference_an_xml_file
        end
      end
      
      it "should have an MDTYPE of DAITSS" do   # For now...
        @digiprov.each do |dp|
          dp.xpath('./xmlns:mdRef', @xmlns).first['MDTYPE'].should eql('OTHER')
          dp.xpath('./xmlns:mdRef', @xmlns).first['OTHERMDTYPE'].should eql('DAITSS')
        end
      end
      
    end

  end

  it "should have a fileSec" do
    @doc.should have_xpath('//xmlns:fileSec', @xmlns)
  end
  
  describe "the fileSec" do

    it "should point to representation descriptors" do
      # Validate each file representation descriptor.
      @files.each do |f|
        f['ID'].should_not be_nil
        f['CHECKSUM'].should_not be_nil
        f['CHECKSUMTYPE'].should eql('SHA-1')
        f.xpath('./xmlns:FLocat', @xmlns).first.should reference_a_file      
      end    
    end

    it "should have an ADMID pointing to a digiprov for each file in the filesec" do
      admids = @digiprov.map { |f| f['ID'] }
      @files.each { |f| admids.should include(f['ADMID']) }
    end    

  end
  
  describe "the struct map" do
    it "should have a file pointer for each file in the filesec" do
      fptrs = @divs.xpath('./xmlns:fptr', @xmlns).map { |fp| fp['FILEID'] }
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
