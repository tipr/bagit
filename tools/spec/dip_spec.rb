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
    lambda { DIP.new @path }.should_not raise_error
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
  
  it "should have an original representation" do
    @dip.original_representation.should_not be_nil
  end
  
  it "should have a current representation" do
    @dip.current_representation.should_not be_nil
  end


end
