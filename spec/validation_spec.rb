describe "a valid bag" do
  
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
    
    @bag.manifest!
  end

  after(:each) do
    @sandbox.cleanup!
  end

  it "should validate with no errors" do
    @bag.should be_valid
  end

  it "should not be lewd (some file is not covered by the manifest)" do
    # add a file into the bag through the back door
    open(File.join(@bag.data_dir, 'not-manifested'), 'w') do |io|
      io.puts 'nothing to see here, move along'
    end

    # @bag.should_not be_complete
    @bag.should_not be_valid
    @bag.errors.on(:completeness).should_not be_empty
  end

  it "should not be prude (the manifest covers files that do not exist)" do
    # add a file and then remove it through the back door
    @bag.add_file("file-k") { |io| io.puts 'time to go' }
    @bag.manifest!

    FileUtils::rm File.join(@bag.bag_dir, 'data', 'file-k')

    # @bag.should_not be_complete
    @bag.should_not be_valid
    @bag.errors.on(:completeness).should_not be_empty
  end

  it "should be consistent (fixity)" do
    # tweak a file through the back door
    open(@bag.bag_files[0], 'a') { |io| io.puts 'oops!' }

    # @bag.should_not be_consistent
    @bag.should_not be_valid
    @bag.errors.on(:consistency).should_not be_empty
  end

end
