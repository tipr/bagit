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

  describe "bagit.txt" do

    before do
      path = File.join @bag_path, 'bagit.txt'
      @lines = open(path) { |io| io.readlines }
    end

    it "should create a file bagit.txt on bag initialization" do
      File.join(@bag_path, 'bagit.txt').should exist_on_fs
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

  describe "bag-info.txt" do

    before(:each) do
      path = File.join @bag_path, 'bag-info.txt'
      @lines = open(path) { |io| io.readlines }
    end

    it "should not be empty" do
      @lines.should_not be_empty
    end

    it "should contain lines of the format LABEL: VALUE (like an email header)" do
      @lines.each { |line| line.chomp.should =~ /^[^\s]+\s*:\s+.*$/ }
    end

    it "should be case insensitive with respect to LABELs" do
      path = File.join @bag_path, 'bag-info.txt'
      lambda { @bag.write_bag_info 'foo' => 'lowercase', 'Foo' => 'capital' }.should raise_error(/Multiple labels/)
    end

    it "should fold long VALUEs" do
      
      @bag.write_bag_info 'Lorem' => <<LOREM
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
  eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enimad
  minim veniam, quis nostrud exercitation ullamco laboris nisi ut
  aliquip ex ea commodo consequat. Duis aute irure dolor in
  reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
  pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
  culpa qui officia deserunt mollit anim id est laborum.
LOREM
      @bag.bag_info.keys.size.should == 1
    end

  end

end
