require 'spec_helper'

describe "BagIt Manifests" do

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

  end

  after(:each) do
    @sandbox.cleanup!
  end

  shared_examples_for "a manifest file" do

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
        File.open(file) do |io|
          io.each_line { |line| line.chomp.should =~ /^[a-fA-F0-9]+\s+[^\s].+$/ }
        end
      end
    end

    it "should validate after adding a file and remanifesting" do
      @bag.add_file('newfile.txt') { |io| io.puts("new file to remanifest") }
      @bag.manifest!
      @bag.should be_valid
    end

  end

  describe "bag manifest files" do

    before do
      @bag.manifest!
    end

    it_behaves_like "a manifest file"

    it "should have a manifest file" do
      @bag.manifest_files.should_not be_empty
    end

    it "should only contain bag files" do
      @bag.manifest_files.each do |mf|
        File.open(mf) do |io|
          io.each_line do |line|
            line.chomp.should =~ /^[a-f0-9]+\s+data\/[^\s].+$/
          end
        end
      end
    end

  end

  describe "an empty bag having manifest! called on it" do

    before do
      Dir[File.join(@bag_path, "/data/*")].each do |file|
        FileUtils::rm file
      end
    end

    it "should raise an error" do
      lambda {@bag.manifest!}.should raise_error("Unable to create manifest because the bag is empty.")
    end
  end

  describe "tag manifest files" do

    before do
      @bag.add_tag_file("test-tag") { |f| f.puts "all alone" }
    end

    it_should_behave_like "a manifest file"

    it "should have a tag manifest file" do
      @bag.tagmanifest_files.should_not be_empty
    end
    it "should only contain tag files" do
      @bag.tagmanifest_files.each do |mf|
        File.open(mf) do |io|
          io.each_line do |line|
            line.chomp.should =~ /^[a-fA-F0-9]+\s+(?!data\/)[^\s].+$/
          end
        end
      end
    end
    it "should contain manifest and bag info files" do
      @bag.tagmanifest_files.each do |mf|
        File.open(mf).read.should include(File.basename(@bag.bag_info_txt_file))
        File.open(mf).read.should include(File.basename(@bag.bagit_txt_file))
        @bag.manifest_files.each do |man|
          File.open(mf).read.should include(man)
        end
      end
    end
    it "should not contain the untracked tag file" do
      @bag.tagmanifest_files.each do |mf|
        File.open(mf) do |io|
          io.read.should_not include "tag-notrack"
        end
      end
    end
    describe "removing tracked files" do
      before(:each) do
        @bag.remove_tag_file "tag-1"
        @bag.delete_tag_file "tag-2"
      end
      it "should still have the untracked tag file on the file system" do
        File.join(@bag_path, "tag-1").should exist_on_fs
      end
      it "should not have the deleted tag file on the file system" do
        File.join(@bag_path, "tag-2").should_not exist_on_fs
      end
      it "should not have the removed or deleted tag files in the manifest" do
        @bag.tagmanifest_files.each do |mf|
          File.open(mf) do |io|
            io.read.should_not include "tag-1"
            io.read.should_not include "tag-2"
          end
        end
      end
    end
  end


end
