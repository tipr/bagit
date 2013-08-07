require 'spec_helper'

# based on v0.96 http://www.cdlib.org/inside/diglib/bagit/bagitspec.html
describe BagIt::Bag do
  describe 'empty bag' do
    before(:each) do
      @sandbox = Sandbox.new
      # make the bag
      @bag_path = File.join @sandbox.to_s, 'the_bag'
      @bag = BagIt::Bag.new @bag_path
    end

    after(:each) do
      @sandbox.cleanup!
    end

    it "should be empty" do
      @bag.should be_empty
    end
  end


  describe 'bag with files' do
    before(:each) do
      @sandbox = Sandbox.new

      # make the bag
      @bag_path = File.join @sandbox.to_s, 'the_bag'
      @bag = BagIt::Bag.new @bag_path

      # add some files
      File.open('/dev/urandom') do |rio|
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

    it "should not be empty" do
      @bag.should_not be_empty
    end

    it "should have a sub-directory called data" do
      data_path = File.join @bag_path, 'data'
      File.directory?(data_path).should be_true
    end

    describe "#add_file" do
      it "should allow addition of files via io" do
        @bag.add_file("foo") { |io| io.puts 'all alone' }
        File.join(@bag_path, "data", "foo").should exist_on_fs
      end

      it "should allow addition of files via copy" do
        src_path = File.join @sandbox.to_s, 'somefile'
        File.open(src_path, 'w') { |io| io.puts "something" }
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

      it "should update payload oxum" do
        oxum_count = @bag.bag_info["Payload-Oxum"].split('.')[1].to_i
        @bag.add_file("foo") { |io| io.puts 'all alone' }
        @bag.bag_info["Payload-Oxum"].split('.')[1].to_i.should == oxum_count + 1
      end
    end

    describe "#remove_file" do
      it "should raise an error when deleing non existant files" do
        lambda { @bag.remove_file("file-x") }.should raise_error
      end
    end

    describe "#get" do
      describe "file not in bag" do
        it "should return nil" do
          @bag.get('foobar').should be_nil
        end
      end

      describe "file in bag" do
        before do
          @contents = 'all alone'
          @bag.add_file("foo") { |io| io << 'all alone' }
          @file = @bag.get("foo")
        end

        it "should return an IO object for the given path" do
          @file.should be_a_kind_of(IO)
        end

        it "should have the same content as the file added" do
          @file.read.should == @contents
        end

        it "should accept an optional leading slash or ./" do
          @bag.get("/foo").read.should == @contents
          @bag.get("./foo").read.should == @contents
        end
      end
    end

    describe "#paths" do
      before do
        @paths = @bag.paths
      end

      it "should return a non-empty Array of Strings" do
        @paths.should be_a_kind_of(Array)
        @paths.should_not be_empty
        @paths.each do |p|
          p.should be_a_kind_of(String)
        end
      end

      it "should return relative paths to all files in the data directory" do
        @paths.should =~ (0..9).collect { |x| "file-#{x}" }
      end
    end

    describe "#payload-oxum" do
      it "should return a valid oxum" do
        @bag.payload_oxum.should =~ /^[0-9]+\.[0-9]+$/
      end

      it "should accurately specify the number of payload files" do
        @bag.add_tag_file('non-payload') { |f| f.puts "I shouldn't count in the oxum" }
        @bag.payload_oxum.split('.')[1] == @bag.bag_files.count
      end
    end

    describe "#gc!" do
      it "should clean up empty directories" do
        f = File.join "1", "2", "3", "file"
        @bag.add_file(f) { |io| io.puts 'all alone' }
        @bag.remove_file f
        File.exist?(File.dirname(File.join(@bag_path, 'data', f))).should be_true
        @bag.gc!
        File.exist?(File.dirname(File.join(@bag_path, 'data', f))).should be_false
      end
    end
  end
end
