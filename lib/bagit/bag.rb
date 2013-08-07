require 'bagit/fetch'
require 'bagit/file'
require 'bagit/info'
require 'bagit/manifest'
require 'bagit/string'
require 'bagit/valid'

module BagIt

  # Represents the state of a bag on a filesystem
  class Bag
    attr_reader :bag_dir

    include Validity            # Validity functionality
    include Info                # bagit & bag info functionality
    include Manifest            # manifest related functionality
    include Fetch               # fetch related functionality

    # Make a new Bag based at path
    def initialize(path, info={})
      @bag_dir = path

      # make the dir structure if it doesn't exist
      FileUtils::mkdir bag_dir unless File.directory? bag_dir
      FileUtils::mkdir data_dir unless File.directory? data_dir

      # write some tag info if its not there
      unless File.exist? bagit_txt_file
        write_bagit("BagIt-Version" => SPEC_VERSION, "Tag-File-Character-Encoding" => "UTF-8")
      end

      unless File.exist? bag_info_txt_file
        write_bag_info(info)
      end
    end

    # Return the path to the data directory
    def data_dir
      File.join @bag_dir, 'data'
    end

    # Return the paths to each bag file relative to bag_dir
    def bag_files
      Dir[File.join(data_dir, '**', '*')].select { |f| File.file? f }
    end

    # Return the paths to each tag file relative to bag_dir
    def tag_files
      files = []
      if tagmanifest_files != []
        File.open(tagmanifest_files.first) do |f|
          f.each_line{|line| files << File.join(@bag_dir, line.split(' ')[1])}
        end
      end
      files
    end

    # Add a bag file
    def add_file(base_path, src_path=nil)
      path = File.join(data_dir, base_path)
      raise "Bag file exists: #{base_path}" if File.exist? path
      FileUtils::mkdir_p File.dirname(path)

      if src_path.nil?
        f = File.open(path, 'w') { |io| yield io }
      else
        f = FileUtils::cp src_path, path
      end
      write_bag_info
      return f
    end

    # Remove a bag file
    def remove_file(base_path)
      path = File.join(data_dir, base_path)
      raise "Bag file does not exist: #{base_path}" unless File.exist? path
      FileUtils::rm path
    end

    # Retrieve the IO handle for a file in the bag
    def get(base_path)
      path = File.join(data_dir, base_path)
      return nil unless File.exist?(path)
      File.open(path)
    end

    # Test if this bag is empty (no files)
    def empty?
      self.bag_files.empty?
    end

    # Get all bag file paths relative to the data dir
    def paths
      self.bag_files.collect { |f| f.sub(data_dir + '/', '') }
    end

    # Get the Oxum for the payload files
    def payload_oxum
      bytes = 0
      bag_files.each do |f|
        #TODO: filesystem quirks? Are we getting the stream size or the size on disk?
        bytes += File.size(f)
      end
      return bytes.to_s + '.' + bag_files.count.to_s
    end

    # Remove all empty directory trees from the bag
    def gc!
      Dir.entries(data_dir).each do |f|
        unless %w{.. .}.include? f
          abs_path = File.join data_dir, f
          File.clean abs_path
        end
      end
    end
  end
end
