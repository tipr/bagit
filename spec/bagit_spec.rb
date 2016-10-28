# coding: utf-8
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
      expect(@bag).to be_empty
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
          @bag.add_file("file-#{n}-💩") { |io| io.write rio.read(16) }
        end
      end
    end

    after(:each) do
      @sandbox.cleanup!
    end

    it "should be a directory" do
      expect(File.directory?(@bag_path)).to be true
    end

    it "should not be empty" do
      expect(@bag).not_to be_empty
    end

    it "should have a sub-directory called data" do
      data_path = File.join @bag_path, 'data'
      expect(File.directory?(data_path)).to be true
    end

    describe "#add_file" do
      it "should allow addition of files via io" do
        @bag.add_file("foo") { |io| io.puts 'all alone' }
        expect(File.join(@bag_path, "data", "foo")).to exist_on_fs
      end

      it "should allow addition of files via copy" do
        src_path = File.join @sandbox.to_s, 'somefile'
        File.open(src_path, 'w') { |io| io.puts "something" }
        @bag.add_file("foo", src_path) { |io| io.puts 'all alone' }
        expect(File.join(@bag_path, "data", "foo")).to exist_on_fs
      end

      it "should allow addition of files with deep paths" do
        @bag.add_file("deep/dir/structure/file") { |io| io.puts 'all alone' }
        expect(File.join(@bag_path, "data", "deep/dir/structure/file")).to exist_on_fs
      end

      it "should not allow overwriting of files" do
        expect { @bag.add_file("file-0-💩") { |io| io.puts 'overwrite!' } }.to raise_error(RuntimeError)
      end

      it "should update payload oxum" do
        oxum_count = @bag.bag_info["Payload-Oxum"].split('.')[1].to_i
        @bag.add_file("foo") { |io| io.puts 'all alone' }
        expect(@bag.bag_info["Payload-Oxum"].split('.')[1].to_i).to eq(oxum_count + 1)
      end
    end

    describe "#remove_file" do
      it "should raise an error when deleing non existant files" do
        expect { @bag.remove_file("file-x") }.to raise_error(RuntimeError)
      end
    end

    describe "#get" do
      describe "file not in bag" do
        it "should return nil" do
          expect(@bag.get('foobar')).to be_nil
        end
      end

      describe "file in bag" do
        before do
          @contents = 'all alone'
          @bag.add_file("foo") { |io| io << 'all alone' }
          @file = @bag.get("foo")
        end

        it "should return an IO object for the given path" do
          expect(@file).to be_a_kind_of(IO)
        end

        it "should have the same content as the file added" do
          expect(@file.read).to eq(@contents)
        end

        it "should accept an optional leading slash or ./" do
          expect(@bag.get("/foo").read).to eq(@contents)
          expect(@bag.get("./foo").read).to eq(@contents)
        end
      end
    end

    describe "#paths" do
      before do
        @paths = @bag.paths
      end

      it "should return a non-empty Array of Strings" do
        expect(@paths).to be_a_kind_of(Array)
        expect(@paths).not_to be_empty
        @paths.each do |p|
          expect(p).to be_a_kind_of(String)
        end
      end

      it "should return relative paths to all files in the data directory" do
        expect(@paths).to match_array((0..9).collect { |x| "file-#{x}-💩" })
      end
    end

    describe "#payload-oxum" do
      it "should return a valid oxum" do
        expect(@bag.payload_oxum).to match(/^[0-9]+\.[0-9]+$/)
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
        expect(File.exist?(File.dirname(File.join(@bag_path, 'data', f)))).to be true
        @bag.gc!
        expect(File.exist?(File.dirname(File.join(@bag_path, 'data', f)))).to be false
      end
    end
  end
end
