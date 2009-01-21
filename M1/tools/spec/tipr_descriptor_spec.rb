require 'erb'
require 'nokogiri'
require 'dip'
require 'spec_helper'

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
  
  it "should be a mets document" do
    @doc.root.name.should == 'mets'
    @doc.root.should be_in_namespace('http://www.loc.gov/METS/')
  end
  
  it "should have an OBJID" do
    @doc.root.attributes['OBJID'].should_not == nil
  end

  it "should have a LABEL" do
    @doc.root.attributes['LABEL'].should_not == nil
  end

  it "should have a mets header" do
    @rchildren.first.name.should == 'metsHdr'
  end

  describe "the header" do
    
    it "should have a create date" do
      @rchildren.first['CREATEDATE'].should_not == nil
    end
    
    it "should have an agent" do
      @rchildren.first.xpath('./xmlns:agent', @xmlns).empty?.should == false
    end

    describe "the agent" do
      it "should have a role of DISSEMINATOR" do
        @rchildren.first.xpath('./xmlns:agent', @xmlns).first['ROLE'].should ==
	  "DISSEMINATOR"
      end  
      
      it "should have a type of ORGANIZATION" do
        @rchildren.first.xpath('./xmlns:agent', @xmlns).first['TYPE'].should ==
	  "ORGANIZATION"
      end
      
      it "should have name of the contributing repository" do
        @rchildren.first.xpath('./xmlns:agent/xmlns:name',
				@xmlns).first.content.should_not == nil
      end    
    end
  end

  it "should not have a dmdSec" do
    @doc.root.xpath('//xmlns:dmdSec', @xmlns).empty?.should == true
  end
  it "should have an amdSec" do
    @doc.root.xpath('//xmlns:amdSec', @xmlns).empty?.should == false
  end

  describe "the amdSec" do
    it "should not have a techMD" do
      @doc.root.xpath('//xmlns:amdSec/xmlns:techMD', @xmlns).empty?.should ==
        true
    end
    
    it "should not have a sourceMD" do
      @doc.root.xpath('//xmlns:amdSec/xmlns:sourceMD', @xmlns).empty?.should ==
        true
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

  it "should have a fileSec that points to representation descriptors" do
    # Validate each file representation descriptor.
    @files.each do |f|
      f['ID'].should_not == nil
      f['CHECKSUM'].should_not == nil
      f['CHECKSUMTYPE'].should == 'SHA-1'
      f.xpath('./xmlns:FLocat', @xmlns).first.should reference_an_xml_file      
    end    
  end

  it "should have a struct map" do
    @doc.root.xpath('//xmlns:structMap', @xmlns).empty?.should == false
  end

  describe "the struct map" do
    it "should have at least two divs" do
      @divs.size.should >= 2
    end

    it "should have all divs be ordered" do
      orders = @divs.select { |div| div['ORDER'] != nil}     # Exclude unordered
      o = orders.map { |d| Integer(d['ORDER']) }             # Map to ints
      1.upto(@divs.size) { |i| o.include?(i).should == true }# Verify content
    end

    it "should have exactly one div labeled active" do
      active = @divs.select { |div| div['TYPE']=='ACTIVE' }
      active.length.should == 1
    end

    it "should have a file pointer for each file in the filesec" do
      fptrs = @divs.xpath('./xmlns:fptr', @xmlns).map { |fp| fp['FILEID'] }
      @files.each { |f| fptrs.include?(f['ID']).should == true }   
    end
  end

end
