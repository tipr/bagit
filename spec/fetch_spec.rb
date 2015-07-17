require 'spec_helper'

describe "fetch.txt" do

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

  before(:each) do
    @bag.add_remote_file('http://www.gnu.org/graphics/heckert_gnu.small.png', 'gnu.png', 6322,
                         '390c0a30976f899cbdf951eab5cce60fe9743ac9',
                         'a3bd7ab2442028bb91b51d9f6722ec98')

    path = File.join @bag_path, 'fetch.txt'
    @lines = File.open(path) { |io| io.readlines }
  end

  it "should not be empty" do
    @lines.should_not be_empty
  end

  it "should only contain lines of the format URL LENGTH FILENAME" do
    @lines.each { |line| line.chomp.should =~ /^[^\s]+\s+(\d+|\-)\s+[^\s]+$/ }
  end

  it "should contain manifested files" do
    path = File.join @bag_path, 'manifest-sha1.txt'
    data = File.open(path) { |io| io.read }
    data.should include('gnu.png')
  end

  it "should be gone when fetch is complete" do
    @bag.fetch!
    fetch_txt = File.join(@bag_path, 'fetch.txt')
    expect(File.exist?(fetch_txt)).to be false
  end

end
