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
  end
  
  it "should be a mets document" do
    @doc.root.name.should == 'mets'
    @doc.root.should be_in_namespace('http://www.loc.gov/METS/')
  end
  
  it "should have an OBJID"
  it "should have a LABEL"

  it "should have a mets header"

  describe "the header" do
    it "should have a create date"
    it "should have an agent"

    describe "the agent" do
      it "should have a role of DISSEMINATOR"
      it "should have a type of ORGANIZATION"
      it "should have name of the contributing repository"
    end

  end

  it "should not have a dmdSec"
  it "should have an amdSec"

  describe "the amdSec" do
    it "should not have a techMD"
    it "should not have a sourceMD"
    it "should have a rightsMD that references an xml file"
    it "should have a digiprovMD that references an xml file"
  end

  it "should have a fileSec that points to representation descriptors"
  it "should have a struct map"

  describe "the struct map" do
    it "should have at least two divs"
    it "should have all divs be ordered"
    it "should have one div labeled active"
    it "should have a file pointer for each file in the filesec"
  end

end
