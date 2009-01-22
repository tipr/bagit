require 'erb'
require 'nokogiri'
require 'dip'
require 'spec_helper'
require 'all_tipr_files_spec'

describe "the tipr descriptor" do
  
  before(:each) do
    # need a daitss DIP
    path = File.join '..', 'DIPs', 'FDA0666001'
    @dip = DIP.new path

    # need the tipr.xml template
    template = open File.join('templates', 'tipr.xml.erb') do |io|
      string = io.read
      ERB.new string
    end
    
    # code to complete the template
    raw_xml = template.result binding
    @doc = Nokogiri::XML raw_xml   

    # some additional instance variables to help clean up the code
    @xmlns = { 'xmlns' => 'http://www.loc.gov/METS/' }  
    @rchildren = @doc.root.children.select { |child| child.name != 'text'}
    @divs = @doc.root.xpath('//xmlns:structMap/xmlns:div/xmlns:div', @xmlns)
    @files = @doc.root.xpath('//xmlns:fileSec//xmlns:file', @xmlns)
  end
  
  # Check mets document, header, and fileSec requirements. 
  it_should_behave_like AllTiprFiles
  
  it "should not have a dmdSec" do
    @doc.root.should_not have_xpath('//xmlns:dmdSec', @xmlns)
  end
  
  it "should have an amdSec" do
    @doc.root.should have_xpath('//xmlns:amdSec', @xmlns)
  end

  describe "the amdSec" do
    it "should not have a techMD" do
      @doc.root.should_not have_xpath('//xmlns:amdSec/xmlns:techMD', @xmlns)
    end
    
    it "should not have a sourceMD" do
      @doc.root.should_not have_xpath('//xmlns:amdSec/xmlns:sourceMD', @xmlns)
    end
    
    it "should have a rightsMD that references an xml file" do
      @doc.root.xpath('//xmlns:amdSec/xmlns:rightsMD/xmlns:mdRef', 
      		@xmlns).first.should reference_an_xml_file
    end
    
    it "should have a digiprovMD that references an xml file" do
      @doc.root.xpath('./xmlns:amdSec/xmlns:digiprovMD/xmlns:mdRef', 
      		@xmlns).first.should reference_an_xml_file
    end    
  end

  it "should have a struct map" do
    @doc.root.should have_xpath('//xmlns:structMap', @xmlns)
  end

  describe "the struct map" do
    it "should have at least two divs" do
      @divs.size.should >= 2
    end

    it "should have all divs be ordered" do
      orders = @divs.select { |div| div['ORDER']}     # Exclude unordered
      o = orders.map { |d| Integer(d['ORDER']) }      # Map to ints
      1.upto(@divs.size) { |i| o.should include(i) }  # Verify content
    end

    it "should have exactly one div labeled active" do
      active = @divs.select { |div| div['TYPE']=='ACTIVE' }
      active.length.should == 1
    end

    it "should have a file pointer for each file in the filesec" do
      fptrs = @divs.xpath('./xmlns:fptr', @xmlns).map { |fp| fp['FILEID'] }
      @files.each { |f| fptrs.should include(f['ID']) }   
    end
  end

end
