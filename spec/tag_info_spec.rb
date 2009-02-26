describe "Tag Info Files" do
  
  before(:each) do

    @sandbox = Sandbox.new

    # make the bag
    @bag_path = File.join @sandbox.to_s, 'the_bag'
    @bag = BagIt::Bag.new @bag_path

    # add some files
    open('/dev/random') do |rio|
      10.times do |n|
        @bag.add_file("file-#{n}") { |io| io.write rio.read(16) }
      end
    end

  end

  after(:each) do
    @sandbox.cleanup!
  end
  
  it "should have at least one manifest-[algorithm].txt" do
    pending "should be a package validation issue, not a spec issue"
    @bag.manifest!
    pattern = File.join @bag_path, 'manifest-*.txt'
    Dir.glob(pattern).should_not be_empty
  end

  it "should have a file bagit.txt" do
    pending "should be a package validation issue, not a spec issue"
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
      a = @lines.select { |line| line.chomp =~ /BagIt-Version:\s*\d+\.\d+/ }
      a.should_not be_empty
    end

    it "should have a tag file encoding" do
      a = @lines.select { |line| line.chomp =~ /Tag-File-Character-Encoding:\s*.+/ }
      a.should_not be_empty
    end

  end
  
  # this is a WIP
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

      # no nerfworld with unexpected results or a fragile exception
      # bomb, this is a toolkit
      pending "Validity should check these files not the construction"

      path = File.join @bag_path, 'package-info.txt'

      @bag.write_package_info 'Foo' => 'bar'
      pre = @bag.package_info.keys

      @bag.set_package_info 'foo' => 'bar'
      post = @bag.package_info.keys

      post.should == pre
    end

    it "may have folded VALUEs" do

      pending "Validity should check these files not the construction"

      pre = @bag.package_info.keys.size
      @bag.write_package_info 'Foo' => <<LOREM
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
  eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enimad
  minim veniam, quis nostrud exercitation ullamco laboris nisi ut
  aliquip ex ea commodo consequat. Duis aute irure dolor in
  reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
  pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
  culpa qui officia deserunt mollit anim id est laborum.
LOREM
      post = @bag.package_info.keys.size
      post.should == (pre + 1)
    end

  end
  
end
