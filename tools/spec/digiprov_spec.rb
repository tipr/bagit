require 'erb'
require 'nokogiri'
require 'dip'
require 'tipr'
require 'spec_helper'

describe "the file digiprov descriptor" do

  before(:each) do

    # define our namespace
    @xmlns = { 'xmlns' => 'http://www.loc.gov/standards/premis/v1' } 

    # need a daitss DIP
    path = File.join '..', 'DIPs', 'FDA0666002'
    @dip = DIP.new path
    
    # need our DAITSS events (we choose the ones in our dip related to the jpg)
    @events = @dip.events('FID1')

    # generate our xml
    t = open File.join('templates', 'digiprov.xml.erb') do |io|
      string = io.read
      ERB.new(string, nil, '<>')
    end
    
    raw_xml = t.result binding
    @doc = Nokogiri::XML raw_xml
 
  end

  it "should be a premis file" do
    @doc.root.name.should eql('premis')
    @doc.root.should be_in_namespace('http://www.loc.gov/standards/premis/v1')    
  end
  
  it "should have an event section" do
    @doc.root.xpath('./xmlns:event', @xmlns).should_not be_empty
  end

  it "should have three events" do		# In our jpg case
    @doc.root.xpath('./xmlns:event', @xmlns).length.should == 3
  end
  
  describe "each event section" do
 
    it "should have an eventIdentifier" do
      @doc.root.should have_xpath('./xmlns:event/xmlns:eventIdentifier', @xmlns)
    end
    
    describe "the event identifier" do
    
      it "should have an eventIdentifierType" do
        @doc.root.xpath('//xmlns:eventIdentifier/xmlns:eventIdentifierType', 
                        @xmlns).should have_node_content("URI")
      end
      
      it "should have an eventIdentifierValue which matches the daitss:event id" do
        @doc.root.xpath('//xmlns:eventIdentifier/xmlns:eventIdentifierValue', 
                        @xmlns).should have_node_content(['488374', '488375', '488380'])
      end
    end
    
    it "should have an eventType" do
      @doc.root.xpath('./xmlns:event/xmlns:eventType', 
        @xmlns).should have_node_content(["Virus check", "Verify checksum", "Migrated"])
    end

    it "should have an eventDateTime" do

      # convert real times to required xml schema (80611) format
      rts = ['2009-01-27 14:32:12', '2009-01-27 14:32:14', '2009-01-27 14:32:35'].map do |s|
        Time.parse(s).xmlschema
      end
      
      @doc.root.xpath('./xmlns:event/xmlns:eventDateTime', 
                      @xmlns).should have_node_content(rts)
    end
    
    it "should have an eventDetail which matches the daitss:procedure" do
      details = [ "Checked for virus during DataFile creation", "compareMessageDigests",
                  "Create a jp2 file migrated from a jpeg file" ]
      @doc.root.xpath('./xmlns:event/xmlns:eventDetail', 
                      @xmlns).should have_node_content(details)
    end
    
    it "should have eventOutcomeInformation" do
      @doc.root.should have_xpath('./xmlns:event/xmlns:eventOutcomeInformation', @xmlns)
    end

    describe "the eventOutcomeInformation" do

      it "should have eventOutcome which matches the daitss:outcome for the event" do
        @doc.root.xpath('//xmlns:eventOutcomeInformation/xmlns:eventOutcome', 
                        @xmlns).should have_node_content("SUCCESS")
      end
      
      it "should have eventOutcomeDetail which matches the daitss:note for the event" do
        details=[ "", 
                  "Compared archive-calculated checksum to submitted checksum. Type: sha-1",
                  "File derived from: /stage/var/daitss/ingest/work/FDA0666002/E20090127_AAAAAA/ateam.jpg" ]

        @doc.root.xpath('//xmlns:eventOutcomeInformation/xmlns:eventOutcomeDetail',
                        @xmlns).should have_node_content(details)
      end
            
    end
    
  end
 
end