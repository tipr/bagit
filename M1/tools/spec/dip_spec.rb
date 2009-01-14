require 'dip'

# A model for a DAITSS AIP that provides functionality for
# constructing a TIPR package
describe DIP do
  
  it "should be initialized from a DAITSS DIP" do
    path = File.join '..', '..', 'FDA0666001'
    DIP.new path
  end
  
  it "should have an IEID"
  it "should have a package ID"
  it "should have a creation date"
  it "should have multiple representations"
  
  describe Representation do
    it "should be a set of files"
    it "should have a sha-1 digest for each file"
  end

end
