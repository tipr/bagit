require 'spec_helper'

describe "Tag Specs" do

  before(:each) do

    @sandbox = Sandbox.new

    # make the bag
    @bag_path = File.join @sandbox.to_s, 'the_bag'
    @bag = BagIt::Bag.new @bag_path

    # add some files
    File.open('/dev/urandom') do |rio|

      10.times do |n|
        @bag.add_file("file-#{n}") { |io| io.write rio.read(16) }
        @bag.add_tag_file("tag-#{n}") { |io| io.write rio.read(16)}
      end

    end

  end

  after(:each) do
    @sandbox.cleanup!
  end
  describe "#add_tag_file" do
    it "should allow addition of tag files via io" do
      @bag.add_tag_file("foo") { |io| io.puts 'all alone' }
      File.join(@bag_path, "foo").should exist_on_fs
    end
    it "should allow addition of bag files within directories using io" do
      @bag.add_tag_file("fedora/foo") { |io| io.puts 'all alone' }
      File.join(@bag_path, "fedora","foo").should exist_on_fs
    end
    it "should allow addition of deep tag files" do
      @bag.add_tag_file("fedora/foo/newfoo/deep") {|io| io.puts "woah that's deep"}
      File.join(@bag_path,"fedora","foo","newfoo","deep").should exist_on_fs
    end
    it "should not allow overwriting of tag files" do
      lambda { @bag.add_tag_file("tag-0") { |io| io.puts 'overwrite!' } }.should raise_error
    end
    it "should allow addition of tag files via copy" do
      src_path = File.join @sandbox.to_s, 'somefile'
      File.open(src_path, 'w') { |io| io.puts "something" }
      @bag.add_tag_file("foo", src_path) { |io| io.puts 'all alone' }
      File.join(@bag_path, "foo").should exist_on_fs
    end
  end
  describe "#remove_tag_file" do
    it "should raise an error when removing non existant files" do
      lambda { @bag.remove_tag_file("file-x") }.should raise_error
    end
  end
  describe "#delete_tag_file" do
    it "should raise an error when deleting non existant tag files" do
      lambda { @bag.delete_tag_file("file-x") }.should raise_error
  end
  end
end