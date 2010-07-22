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

    private_class_method :new

    def initialize(path)
      @bag_dir = path
    end

    def self.create(path)
      new path
    end

    def self.create!(path)
      bag = new path

      # check to make sure that they don't exist already
      raise "Unable to create Bag at: ", path, ", exists already: ", bag.bag_dir if File.exists? bag.bag_dir
      raise "Unable to create Bag at: ", path, ", exists already: ", bag.data_dir if File.exists? bag.data_dir
      raise "Unable to create Bag at: ", path, ", exists already: ", bag.bagit_txt_file if File.exists? bag.bagit_txt_file
      raise "Unable to create Bag at: ", path, ", exists already: ", bag.bag_info_txt_file if File.exists? bag.bag_info_txt_file

      # these don't exist. Create them.
      FileUtils::mkdir bag.bag_dir 
      FileUtils::mkdir bag.data_dir       
      bag.write_new_bagit
      bag.write_new_bag_info
      
      #return the new bag
      bag
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
      Dir[File.join(@bag_dir, '*')].select { |f| File.file? f }
    end

    # Add a bag file
    def add_file(base_path, src_path=nil)
      path = File.join(data_dir, base_path)
      raise "Bag file exists: #{base_path}" if File.exist? path
      FileUtils::mkdir_p File.dirname(path)

      if src_path.nil?
        open(path, 'w') { |io| yield io }
      else
        FileUtils::cp src_path, path
      end
      
    end

    # Remove a bag file
    def remove_file(base_path)
      path = File.join(data_dir, base_path)
      raise "Bag file does not exist: #{base_path}" unless File.exist? path
      FileUtils::rm path
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

