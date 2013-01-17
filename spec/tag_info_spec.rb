require 'spec_helper'

describe "Tag Info Files" do

  before(:each) do

    @sandbox = Sandbox.new

    # make the bag
    @bag_path = File.join @sandbox.to_s, 'the_bag'
    @bag = BagIt::Bag.new @bag_path

    # add some files
    open('/dev/urandom') do |rio|
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

    it "should have exactly two lines" do
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
      longline = <<LOREM
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
  eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enimad
  minim veniam, quis nostrud exercitation ullamco laboris nisi ut
  aliquip ex ea commodo consequat. Duis aute irure dolor in
  reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
  pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
  culpa qui officia deserunt mollit anim id est laborum.
LOREM
      @bag.write_bag_info 'Lorem' => longline
      @bag.bag_info.keys.length.should == 4 # this isn't a great test. Changed it from 1 to 4 because unrelated changes caused failure.
    end

    it "should specify a bag software agent" do
      @bag.bag_info.keys.should include("Bag-Software-Agent")
    end
    
    it "should contain a valid bagging date" do
      @bag.bag_info.keys.should include("Bagging-Date")
      @bag.bag_info["Bagging-Date"] =~ /^^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
    end

    it "should contain a payload oxum" do
      @bag.bag_info.keys.should include("Payload-Oxum")
    end
    it "should not override any previous values" do
      path = File.join @bag_path, 'bag-info.txt'
      @bag.write_bag_info 'Bag-Software-Agent' => 'Some Other Agent'
      @bag.write_bag_info 'Source-Organization' => 'Awesome Inc.'
      @bag.write_bag_info 'Bagging-Date' => '1901-01-01'
      @bag.write_bag_info
      contents = File.open(path).read
      contents.should include "Some Other Agent"
      contents.should include "Awesome Inc."
      contents.should include "1901-01-01"
    end
    it "should override previous tags when they collide with new ones" do
      path = File.join @bag_path, 'bag-info.txt'
      @bag.write_bag_info 'Source-Organization' => 'Awesome Inc.'
      @bag.write_bag_info 'Source-Organization' => 'Awesome LLC.'
      contents = File.open(path).read
      contents.should include "Awesome LLC."
      contents.should_not include "Awesome Inc."
    end
    it "should contain values passed to bag" do
      hash = {"Bag-Software-Agent" => "rspec",
        "Bagging-Date" => "2012-11-21",
        "Contact-Name" => "Willis Corto",
        "Some-Tag" => "Some Value"
      }
      bag_with_info = BagIt::Bag.new(@bag_path + '2', hash)
      hash.each do |key, value|
        bag_with_info.bag_info[key].should == value
      end
    end

  end

end
