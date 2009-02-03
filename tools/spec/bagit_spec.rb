require 'bagit'
require 'tempfile'

# based on v0.95 http://www.cdlib.org/inside/diglib/bagit/bagitspec.html
describe Bagit::Bag do

  before(:each) do
    
    # make a sandbox to play in
    tf = Tempfile.open 'sandbox'
    @sandbox_path = tf.path
    tf.close!
    FileUtils::mkdir @sandbox_path

    # make the bag
    @bag_path = File.join @sandbox_path, 'the_bag'
    @bag = Bagit::Bag.new @bag_path

    # add some files
    open('/dev/random') do |rio|
      10.times do |n|
        @bag.add_file("file-#{n}") { |io| io.write rio.read(16) }
      end
    end
    
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

    it "should be a subset of files in the manifests"

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
      pre = @bag.read_package_info.keys

      @bag.set_package_info 'foo', 'bar'
      post = @bag.read_package_info.keys

      post.should == pre
    end

    it "may have folded VALUEs" do

      pre = @bag.read_package_info.keys.size
      @bag.set_package_info 'Foo', <<LOREM
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
  eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enimad
  minim veniam, quis nostrud exercitation ullamco laboris nisi ut
  aliquip ex ea commodo consequat. Duis aute irure dolor in
  reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
  pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
  culpa qui officia deserunt mollit anim id est laborum.
LOREM
      post = @bag.read_package_info.keys.size
      post.should == (pre + 1)
    end

  end

  describe "an invalid bag" do
    it "should not be valid if incomplete (some file is not manifested)" do
      @bag.should be_complete
      @bag.should be_valid

      # add a file into the bag through the back door
      open(File.join(@bag.data_dir, 'not-manifested'), 'w') do |io|
        io.puts 'nothing to see here, move along'
      end

      @bag.should_not be_complete
      @bag.should_not be_valid
    end

    it "should not be valid if some manifested file is not present" do
      @bag.should be_complete
      @bag.should be_valid

      # remove a file through the back door
      FileUtils::rm @bag.data_files[0]

      @bag.should_not be_complete
      @bag.should_not be_valid
    end

    it "should not be balid if some file is not fixed" do
      @bag.should be_fixed
      @bag.should be_valid

      # remove a file through the back door
      open(@bag.data_files[0], 'a') { |io| io.puts 'oops!' }

      @bag.should_not be_fixed
      @bag.should_not be_valid
    end

  end

end


describe "serialization" do
  it "should contain only bag"
  it "should have the same basename as the bag's base dir"
  it "should produce a single top level bad dir"
  it "should preserve the validity of the bag"
end
