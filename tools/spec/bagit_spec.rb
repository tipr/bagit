require 'bagit'
require 'tempfile'

# based on v0.95 http://www.cdlib.org/inside/diglib/bagit/bagitspec.html
describe Bagit do

  before(:each) do
    # make some temp data to bag
    tf = Tempfile.open 'sandbox'
    @sandbox_path = tf.path
    tf.close!
    FileUtils::mkdir @sandbox_path

    # make some source data
    source_data_path = File.join @sandbox_path, 'source_data'
    FileUtils::mkdir source_data_path

    open('/dev/random') do |rio|

      10.times do

        Tempfile.open('content-file',  source_data_path) do |tio|
          data = rio.read 16
          tio.write data
          tio.flush
        end

      end

    end

    # make the bag
    @bag_path = File.join @sandbox_path, 'the_bag'
    @bag = Bagit.new source_data_path
    @bag.save @bag_path
  end

  after(:each) do
    # cleanup
    FileUtils::rm_rf @sandbox_path
  end

  it "should be a directory" do
    File.directory?(@bag_path).should be_true
  end

  it "should have a sub-directory called data" do
    data_path = File.join @bag_path, 'data'
    File.directory?(data_path).should be_true
  end

  it "should have at least one manifest-[algorithm].txt" do
    pattern = File.join @bag_path, 'manifest-*.txt'
    Dir.glob(pattern).should_not be_empty
  end

  it "should have a file bagit.txt" do
    path = File.join @bag_path, 'bagit.txt'
    File.file?(path).should be_true
  end

  describe "bagit.txt" do
    
    before do
      path = File.join @bag_path, 'bagit.txt'
      @lines = open(path) { |io| io.readlines }
    end
    
    it "should have exaclty two lines" do
      @lines.size.should == 2
    end
    
    it "should have a bagit version" do
      # TODO this nees a better matcher
      a = @lines.select { |line| line.chomp =~ /BagIt-Version:\s*\d+\.\d+/ }
      a.should_not be_empty
    end
    
    it "should have a tag file encoding" do
      a = @lines.select { |line| line.chomp =~ /Tag-File-Character-Encoding:\s*.+/ }
      a.should_not be_empty
    end
    
  end

  it "may have zero ormore additional files"

  describe "manifest-[algorithm].txt" do
    it "should have valid algorithm in the name (at least md5 and sha1)"
    it "should only contain lines of the format CHECKSUM FILENAME"
    it "should only use the slash character as a path separator in FILENAME"
    it "should only use hex-encoded checksums"
    it "should contain FILENAMEs that are relative paths from the base directory"
    it "should have one or more whitespace characters separating fields"
  end

  describe "fetch.txt" do
    it "should only contain lines of the format URL LENGTH FILENAME"
    it "should only have cannonical URLs"
    it "should only have a positive integer or - (unspecified) for LENGTH"
    it "should only use the slash character as a path separator in FILENAME"
    it "should contain FILENAMEs that are relative paths from the base directory"
    it "should have one or more whitespace characters separating fields"
    it "should be renamed when receipt of a bag is complete"
  end

  describe "tagmanifest-[algorithm].txt" do
    it "should work just like a nomral manifest file, but only contain tag files"
  end

  describe "a valid bag" do
    it "should have every present payload file manifested at least once"
    it "should have all manifested files present"
    it "should have verified checksums of all manifested files"
  end

  describe "bag-info.txt" do
    it "should not be empty"
    it "should contain lines of the format LABEL : VALUE"
    it "should be case insensitive with respect to LABELs"
    it "may have folded VALUEs"
  end

  describe "serialization" do
    it "should contain only bag"
    it "should have the same basename as the bag's base dir"
    it "should produce a single top level bad dir"
    it "should preserve the validity of the bag"
  end

end


