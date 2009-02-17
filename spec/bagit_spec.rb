require 'bagit'
require 'tempfile'
require 'spec_helper'

# based on v0.95 http://www.cdlib.org/inside/diglib/bagit/bagitspec.html
describe BagIt::Bag do

  before(:each) do

    # make a sandbox to play in
    tf = Tempfile.open 'sandbox'
    @sandbox_path = tf.path
    tf.close!
    FileUtils::mkdir @sandbox_path

    # make the bag
    @bag_path = File.join @sandbox_path, 'the_bag'
    @bag = BagIt::Bag.new @bag_path

    # add some files
    open('/dev/random') do |rio|
      10.times do |n|
        @bag.add_file("file-#{n}") { |io| io.write rio.read(16) }
      end
    end

  end

  after(:each) do
    FileUtils::rm_rf @sandbox_path # cleanup
  end

  it "should be a directory" do
    File.directory?(@bag_path).should be_true
  end

  it "should have a sub-directory called data" do
    data_path = File.join @bag_path, 'data'
    File.directory?(data_path).should be_true
  end

  it "should have at least one manifest-[algorithm].txt" do
    @bag.manifest!
    pattern = File.join @bag_path, 'manifest-*.txt'
    Dir.glob(pattern).should_not be_empty
  end

  it "should have a file bagit.txt" do
    path = File.join @bag_path, 'bagit.txt'
    File.file?(path).should be_true
  end

  it "should allow addition of files with deep paths" do
    lambda { @bag.add_file("deep/dir/structure/file") { |io| io.puts 'all alone' } }.should_not raise_error
  end
  
  it "should clean up empty directories" do
    f = File.join "1", "2", "3", "file"
    @bag.add_file(f) { |io| io.puts 'all alone' }
    @bag.remove_file f
    File.exist?(File.dirname(File.join(@bag_path, 'data', f))).should be_true
    @bag.gc!
    File.exist?(File.dirname(File.join(@bag_path, 'data', f))).should be_false
  end
  
  it "should not allow overwriting of files" do
    lambda { @bag.add_file("file-0") { |io| io.puts 'overwrite!' } }.should raise_error
  end
  
  it "should raise an error when deleing non existant files" do
    lambda { @bag.remove_file("file-x") }.should raise_error
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

  describe "a manifest file", :shared => true do

    before do
      pattern = File.join @bag_path, '*manifest-*.txt'
      @manifest_files = Dir.glob pattern
    end

    it "should have valid algorithm in the name (at least md5 or sha1)" do
      algorithms = @manifest_files.map { |mf| mf =~ /manifest-(.*).txt$/; $1 }
      algorithms.each { |a| a.should be_in('md5', 'sha1') }
    end
    
    it "should not be an empty file" do
      @manifest_files.each { |mf| File.size(mf).should_not == 0 }
    end
    
    it "should only contain lines of the format CHECKSUM FILENAME" do
      @manifest_files.each do |file|
        open(file) do |io|
          io.each_line { |line| line.chomp.should =~ /^[a-fA-F0-9]+\s+[^\s].+$/ }
        end
      end
    end
    
  end

  describe "bag manifest files" do

    before do
      @bag.manifest!
    end
    
    it_should_behave_like "a manifest file"

    it "should have a manifest file" do
      @bag.manifest_files.should_not be_empty
    end

    it "should only contain bag files" do
      @bag.manifest_files.each do |mf|
        open(mf) do |io|
          io.each_line do |line|
            line.chomp.should =~ /^[a-f0-9]+\s+data\/[^\s].+$/            
          end
        end
      end
    end

  end

  describe "tag manifest files" do
    
    before do
      @bag.tagmanifest!
    end

    it_should_behave_like "a manifest file"
    
    it "should have a tag manifest file" do
      @bag.tagmanifest_files.should_not be_empty
    end
    
    it "should only contain tag files" do
      @bag.tagmanifest_files.each do |mf|
        open(mf) do |io|
          io.each_line do |line|
            line.chomp.should =~ /^[a-fA-F0-9]+\s+(?!data\/)[^\s].+$/
          end
        end
      end
    end
    
  end
  
  describe "fetch.txt" do

    before(:each) do
      @bag.add_remote_file('http://www.gnu.org/graphics/heckert_gnu.small.png', 'gnu.png', 6322,
                           '390c0a30976f899cbdf951eab5cce60fe9743ac9',
                           'a3bd7ab2442028bb91b51d9f6722ec98')

      path = File.join @bag_path, 'fetch.txt'
      @lines = open(path) { |io| io.readlines }
    end

    it "should not be empty" do
      @lines.should_not be_empty
    end

    it "should only contain lines of the format URL LENGTH FILENAME" do
      @lines.each { |line| line.chomp.should =~ /^[^\s]+\s+(\d+|\-)\s+[^\s]+$/ }
    end

    it "should contain manifested files" do
      path = File.join @bag_path, 'manifest-sha1.txt'
      data = open(path) { |io| io.read }
      data.should include('gnu.png')
    end

    it "should be gone when fetch is complete" do
      @bag.fetch!
      File.exist?(File.join(@bag_path, 'fetch.txt')).should_not be_true
    end

  end
  
  # TODO rework this to be dubmer and simpler
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

    before(:each) do
      @bag.manifest!
      @bag.should be_all_files_manifested
      @bag.should be_all_manifestations_present
    end

    it "should not be valid if incomplete (some file is not manifested)" do
      # add a file into the bag through the back door
      open(File.join(@bag.data_dir, 'not-manifested'), 'w') do |io|
        io.puts 'nothing to see here, move along'
      end

      @bag.should_not be_all_files_manifested
    end

    it "should not be valid if some file is not fixed" do
      # tweak a file through the back door
      open(@bag.bag_files[0], 'a') { |io| io.puts 'oops!' }

      @bag.should_not be_fixed
    end

    it "should not be valid if some manifested file is not present" do
      # add a file and then remove it through the back door
      @bag.add_file("file-k") { |io| io.puts 'time to go' }
      @bag.manifest!
      
      FileUtils::rm File.join(@bag.bag_dir, 'data', 'file-k')

      @bag.should_not be_all_manifestations_present
    end

    it "needs a facility to report errors" do
      pending 'looking into Validatable'
    end
  end

end
