require 'dip'

# A model for a DAITSS AIP that provides functionality for
# constructing a TIPR package
describe DIP do
  
  before do
    @path = File.join '..', 'DIPs', 'FDA0666001'
  end
  
  it "should be initialized from a DAITSS DIP" do
    DIP.new @path
  end
  
  it "should have an IEID" do
    dip = DIP.new @path
    dip.ieid.should == 'E20081121_AAAAEW'
  end
  
  it "should have a package ID"
  it "should have a creation date"
  it "should have multiple representations"
  
  describe Representation do
    it "should be a set of files"
    it "should have a sha-1 digest for each file"
  end

end
