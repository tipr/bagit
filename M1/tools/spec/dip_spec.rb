require 'time'
require 'dip'

# A model for a DAITSS AIP that provides functionality for
# constructing a TIPR package
describe DIP do
  
  before do
    @path = File.join '..', 'DIPs', 'FDA0666001'
    @dip = DIP.new @path
  end
  
  it "should be initialized from a DAITSS DIP" do
    DIP.new @path
  end
  
  it "should have an IEID" do
    @dip.ieid.should == 'E20081121_AAAAEW'
  end
  
  it "should have a package ID" do
    @dip.package_id.should == 'FDA0666001'
  end
  
  it "should have a creation date" do
    @dip.create_date.should == Time.parse('2008-11-21T22:07:57Z')
  end
  
  it "should have multiple representations"
  
  describe Representation do
    it "should be a set of files"
    it "should have a sha-1 digest for each file"
  end

end
