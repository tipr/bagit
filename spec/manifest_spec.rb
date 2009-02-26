describe "BagIt Manifests" do

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


end
