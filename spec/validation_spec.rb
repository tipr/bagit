require 'spec_helper'

describe "a valid bag" do

  before(:each) do

    @sandbox = Sandbox.new

    # make the bag
    @bag_path = File.join @sandbox.to_s, 'the_bag'
    @bag = BagIt::Bag.new @bag_path

    # add some files
    File.open('/dev/urandom') do |rio|

      10.times do |n|
        @bag.add_file("file-#{n}") { |io| io.write rio.read(16) }
        @bag.add_tag_file("tag-#{n}") { |io| io.write rio.read(16) }
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
    File.open(File.join(@bag.data_dir, 'not-manifested'), 'w') do |io|
      io.puts 'nothing to see here, move along'
    end

    @bag.validate_only('true_for/completeness')
    @bag.errors.on(:completeness).should_not be_empty
    @bag.should_not be_valid
  end

  it "should not be prude (the manifest covers files that do not exist)" do
    # add a file and then remove it through the back door
    @bag.add_file("file-k") { |io| io.puts 'time to go' }
    @bag.manifest!

    FileUtils::rm File.join(@bag.bag_dir, 'data', 'file-k')

    @bag.validate_only('true_for/completeness')
    @bag.errors.on(:completeness).should_not be_empty
    @bag.should_not be_valid
  end

  it "should be consistent (fixity)" do
    # tweak a file through the back door
    File.open(@bag.bag_files[0], 'a') { |io| io.puts 'oops!' }

    @bag.validate_only('true_for/consistency')
    @bag.errors.on(:consistency).should_not be_empty
    @bag.should_not be_valid
  end

  it "should calculate sha1 correctly for a big file" do
    @bag.add_file 'big-data-file' do |fh|
      count = 0
      while count < 1024 * 512 do
        fh.write "1" * 1024
        count += 1
      end
    end
    @bag.manifest!
    sha1_manifest = File.join @bag_path, 'manifest-sha1.txt'
    checksums = {}
    File.open(sha1_manifest).each_line do |line|
        fixity, path = line.split(' ')
        checksums[path] = fixity
    end
    expected = checksums['data/big-data-file']
    expected.should == '12be64c30968bb90136ee695dc58f4b2276968c6'
  end

  it "should validate by oxum when needed" do
    @bag.valid_oxum?.should == true
  end

  it "should validate false by oxum when file count is incorrect" do
    # tweak oxum through backdoor
    File.open(@bag.bag_info_txt_file, 'a') { |f| f.write "Payload-Oxum: " + @bag.bag_info["Payload-Oxum"].split('.')[0] + '.0' }
    @bag.valid_oxum?.should == false
  end

  it "should validate false by oxum when octetstream size is incorrect" do
    # tweak oxum through backdoor
    File.open(@bag.bag_info_txt_file, 'a') { |f| f.write "Payload-Oxum: 1." + @bag.bag_info["Payload-Oxum"].split('.')[1] }
    @bag.valid_oxum?.should == false
  end

  describe "tag manifest validation" do
    it "should be invalid if listed tag file does not exist" do
      # add a file and then remove it through the back door
      @bag.add_tag_file("tag-k") { |io| io.puts 'time to go' }
      @bag.tagmanifest!

      FileUtils::rm File.join(@bag.bag_dir, 'tag-k')

      # @bag.should_not be_valid
      @bag.should_not be_valid
      @bag.errors.on(:completeness).should_not be_empty
    end
  end

end
