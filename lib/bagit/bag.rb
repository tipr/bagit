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
    include Validatable
    validates_true_for :consistency, :logic => lambda { complete? }
    validates_true_for :completeness, :logic => lambda { consistent? }

    include Info                # package & bag info functionality
    include Manifest            # manifest related functionality
    include Fetch               # fetch related functionality

    # Make a new Bag based at path
    def initialize(path)
      @bag_dir = path

      # make the dir structure if it doesn't exist
      FileUtils::mkdir bag_dir unless File.directory? bag_dir
      FileUtils::mkdir data_dir unless File.directory? data_dir

      # write the bagit.txt
      write_bag_info "BagIt-Version" => SPEC_VERSION, "Tag-File-Character-Encoding" => "UTF-8"


      # write the package-info.txt
      # TODO this can be simplified
      write_package_info 'Packing-Software' => "Ruby BagIt gem (http://bagit.rubyforge.org)"
    end

    # Return the path to the data directory
    def data_dir
      File.join @bag_dir, 'data'
    end

    # Return the set of paths to each bag file
    def bag_files
      Dir[File.join(data_dir, '**', '*')].select { |f| File.file? f }
    end

    # Return a set of paths to each tag file
    def tag_files
      Dir[File.join(@bag_dir, '*')].select { |f| File.file? f }
    end

    # Add a bag file
    def add_file(base_path)
      path = File.join(data_dir, base_path)
      raise "Bag file exists: #{base_path}" if File.exist? path
      FileUtils::mkdir_p File.dirname(path)
      open(path, 'w') { |io| yield io }
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
