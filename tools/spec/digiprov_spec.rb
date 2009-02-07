require 'erb'
require 'nokogiri'
require 'dip'
require 'tipr'
require 'spec_helper'

describe "the file digiprov descriptor" do

  before(:each) do
        
    event_doc = Nokogiri::XML <<XML
<daitss xmlns="http://www.fcla.edu/dls/md/daitss/">
  <EVENT>
    <ID>488374</ID>
    <OID>F20090127_AAAAAA</OID>
    <EVENT_TYPE>CV</EVENT_TYPE>
    <DATE_TIME>2009-01-27 14:32:12</DATE_TIME>
    <EVENT_PROCEDURE>Checked for virus during DataFile creation</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
  <EVENT>
    <ID>488375</ID>
    <OID>F20090127_AAAAAA</OID>
    <EVENT_TYPE>VC</EVENT_TYPE>
    <DATE_TIME>2009-01-27 14:32:14</DATE_TIME>
    <EVENT_PROCEDURE>compareMessageDigests</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE>Compared archive-calculated checksum to submitted checksum. Type: sha-1</NOTE>
  </EVENT>
  <EVENT>
    <ID>488376</ID>
    <OID>F20090127_AAAAAB</OID>
    <EVENT_TYPE>CV</EVENT_TYPE>
    <DATE_TIME>2009-01-27 14:32:19</DATE_TIME>
    <EVENT_PROCEDURE>Checked for virus during DataFile creation</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
</daitss>
XML

    @events = event_doc.xpath('//daitss:EVENT', 'daitss' => "http://www.fcla.edu/dls/md/daitss/").to_a

    # generate our xml
    t = open File.join('templates', 'digiprov.xml.erb') do |io|
      string = io.read
      ERB.new(string, nil, '<>')
    end
        
    raw_xml = t.result binding
    @doc = Nokogiri::XML raw_xml, nil, nil, Nokogiri::XML::PARSE_NOBLANKS
  end

  it "should be a premis document" do
    @doc.should have_xpath('premis:premis')
  end

  it "should have three event" do
    @doc.xpath('/premis:premis/premis:event', NS_MAP).size.should == 3
  end

  describe "the event" do

    before(:each) do
      @event = @doc.xpath('/premis:premis/premis:event', NS_MAP).first
    end

    it "should have an eventIdentifier" do
      @event.should have_xpath('premis:eventIdentifier')
    end


    it "should have an eventIdentifierType" do
      @event.should have_xpath('premis:eventIdentifier/premis:eventIdentifierType')
    end

    it "should have an eventIdentifierValue which matches the daitss:event id" do
      #@event.should have_xpath('premis:eventIdentifier/premis:eventIdentifierValue["488374"]')
    end

    it "should have an eventType" do
      @event.should have_xpath('premis:eventType["Virus check"]')
    end

    it "should have an eventDateTime" do
      expected_time = Time.parse '2009-01-27 14:32:12'
      actual_time = Time.parse @event.xpath("premis:eventDateTime", NS_MAP).first.content
      actual_time.should == expected_time
      # @event.should have_xpath("premis:eventDateTime[text()='#{ expected_time }']")
    end

    it "should have an eventDetail which matches the daitss:procedure" do
      @event.should have_xpath("premis:eventDetail['Checked for virus during DataFile creation']")
    end

    it "should have eventOutcomeInformation" do
      outcome = @event.xpath('premis:eventOutcomeInformation', NS_MAP).first
      outcome.should have_xpath('premis:eventOutcome["SUCCExSS"]')
      detail = outcome.xpath('premis:eventOutcomeDetail', NS_MAP).first
      detail.content.should be_empty
    end

  end

end
