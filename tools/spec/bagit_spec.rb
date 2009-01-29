require 'bagit'
require 'tempfile'

# based on v0.95 http://www.cdlib.org/inside/diglib/bagit/bagitspec.html
describe Bagit do

  before(:each) do
    # make a sandbox to play in
    tf = Tempfile.open 'sandbox'
    @sandbox_path = tf.path
    tf.close!
    FileUtils::mkdir @sandbox_path

    # make the bag
    @bag_path = File.join @sandbox_path, 'the_bag'
    @bag = Bagit.new @bag_path

    # add some files
    rio = open('/dev/random')
    10.times do |n|
      @bag.add_file("file-#{n}") { |io| io.write rio.read(16) }
    end
    rio.close
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
      # TODO this needs a better matcher
      a = @lines.select { |line| line.chomp =~ /BagIt-Version:\s*\d+\.\d+/ }
      a.should_not be_empty
    end

    it "should have a tag file encoding" do
      # TODO this needs a better matcher
      a = @lines.select { |line| line.chomp =~ /Tag-File-Character-Encoding:\s*.+/ }
      a.should_not be_empty
    end

  end

  # super!
  it "may have zero or more additional files"

  describe "manifest-[algorithm].txt" do

    before do
      pattern = File.join @bag_path, 'manifest-*.txt'
      @manifest_files = Dir.glob pattern
    end

    it "should have at least one" do
      @manifest_files.should_not be_empty
    end

    it "should have valid algorithm in the name (at least md5 or sha1)" do

      @manifest_files.each do |path|
        path =~ /manifest-(.*).txt/
        $1.should be_in('md5', 'sha1')
      end

    end

    it "should only contain lines of the format CHECKSUM FILENAME" do
      @manifest_files.each do |file|
        lines = open(file) { |io| io.readlines }
        lines.should_not be_empty

        lines.each do |line|
          line.chomp.should =~ /^[a-f0-9]+\s+[^\s]+$/
        end

      end

    end

  end

  describe "fetch.txt" do

    before(:each) do
      @bag.add_remote_file 'http://www.gnu.org/graphics/heckert_gnu.small.png', 'gnu.png'

      path = File.join @bag_path, 'fetch.txt'
      @lines = open(path) { |io| io.readlines }
    end

    it "should not be empty" do
      @lines.should_not be_empty
    end

    it "should only contain lines of the format URL LENGTH FILENAME" do

      @lines.each do |line|
        line.chomp.should =~ /^[^\s]+\s+(\d+|\-)\s+[^\s]+$/
      end

    end

    it "should be gone when fetch is complete" do
      @bag.fetch!
      path = File.join @bag_path, 'fetch.txt'
      File.exist?(path).should_not be_true
    end
    
  end

  describe "tagmanifest-[algorithm].txt" do
    it "should work just like a nomral manifest file, but only contain tag files"
  end

  describe "package-info.txt" do
    
    before(:each) do
      path = File.join @bag_path, 'package-info.txt'
      @lines = open(path) { |io| io.readlines }
    end
    
    it "should not be empty" do
      @lines.should_not be_empty
    end
    
    it "should contain lines of the format LABEL: VALUE (like an email header)" do
      @lines.each { |line| line.chomp.should =~ /^[^\s]+\s*:\s+.*$/ }
    end
    
    it "should be case insensitive with respect to LABELs" do
      path = File.join @bag_path, 'package-info.txt'

      @bag.set_package_info 'Foo', 'bar'
      pre = open(path) { |io| io.readlines }.size

      @bag.set_package_info 'foo', 'bar'
      post = open(path) { |io| io.readlines }.size
      
      post.should == pre
    end

    it "may have folded VALUEs"
  end

end

describe "a valid bag" do
  it "should have every present payload file manifested at least once"
  it "should have all manifested files present"
  it "should have verified checksums of all manifested files"
end

describe "serialization" do
  it "should contain only bag"
  it "should have the same basename as the bag's base dir"
  it "should produce a single top level bad dir"
  it "should preserve the validity of the bag"
end

