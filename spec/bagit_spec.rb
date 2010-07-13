require 'bagit'
require 'tempfile'
require 'spec_helper'

# based on v0.96 http://www.cdlib.org/inside/diglib/bagit/bagitspec.html
describe BagIt::Bag do

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

  it "should be a directory" do
    File.directory?(@bag_path).should be_true
  end

  it "should have a sub-directory called data" do
    data_path = File.join @bag_path, 'data'
    File.directory?(data_path).should be_true
  end
  
  it "should allow addition of files via io" do
    @bag.add_file("foo") { |io| io.puts 'all alone' }
    File.join(@bag_path, "data", "foo").should exist_on_fs
  end
  
  it "should allow addition of files via copy" do
    src_path = File.join @sandbox.to_s, 'somefile'
    open(src_path, 'w') { |io| io.puts "something" }
    @bag.add_file("foo", src_path) { |io| io.puts 'all alone' }
    File.join(@bag_path, "data", "foo").should exist_on_fs
  end
  
  it "should allow addition of files with deep paths" do
    @bag.add_file("deep/dir/structure/file") { |io| io.puts 'all alone' }
    File.join(@bag_path, "data", "deep/dir/structure/file").should exist_on_fs
  end
  
  it "should not allow overwriting of files" do
    lambda { @bag.add_file("file-0") { |io| io.puts 'overwrite!' } }.should raise_error
  end

  it "should raise an error when deleing non existant files" do
    lambda { @bag.remove_file("file-x") }.should raise_error
  end
  
  it "should clean up empty directories" do
    f = File.join "1", "2", "3", "file"
    @bag.add_file(f) { |io| io.puts 'all alone' }
    @bag.remove_file f
    File.exist?(File.dirname(File.join(@bag_path, 'data', f))).should be_true
    @bag.gc!
    File.exist?(File.dirname(File.join(@bag_path, 'data', f))).should be_false
  end
  
end
