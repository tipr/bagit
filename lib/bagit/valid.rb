require 'validatable'
require 'open-uri'
require 'cgi'
require 'logger'

module BagIt

  class Bag
    include Validatable
    validates_true_for :consistency, :logic => Proc.new { consistent? }
    validates_true_for :completeness, :logic => Proc.new { complete? }
  end

  module Validity
    def decode_filename(s)
      s = s.gsub('%0D',"\r")
      s = s.gsub('%0A',"\n")
      return s
    end
    
    # Return true if the manifest cover all files and all files are
    # covered.
    def complete?
      logger = Logger.new(STDOUT)
      unmanifested_files.each do |file|
        logger.error("#{file} is present but not manifested".red)
        errors.add :completeness, "#{file} is present but not manifested"
      end

      empty_manifests.each do |file|
        logger.error("#{file} is manifested but not present".red)
        errors.add :completeness, "#{file} is manifested but not present"
      end
      tag_empty_manifests.each do |file|
        logger.error("#{file} is a manifested tag but not present".red)
        errors.add :completeness, "#{file} is a manifested tag but not present"
      end

      errors.on(:completeness).nil?
    end

    # Return true if all manifested files message digests match.
    def consistent?
      (manifest_files|tagmanifest_files).each do |mf|
        # get the algorithm implementation
        File.basename(mf) =~ /manifest-(.+).txt$/
        manifest_type = $1
        algo = case manifest_type
               when /sha1/i
                 Digest::SHA1
               when /md5/i
                 Digest::MD5
               else
                 raise ArgumentError.new("Algorithm #{manifest_type} is not supported.")
               end
        # Check every file in the manifest
        File.open(mf) do |io|
          io.each_line do |line|
            expected, path = line.chomp.split /\s+/, 2
            file = File.join(bag_dir, decode_filename(path))

            if File.exist? file

              actual = algo.file(file).hexdigest
              if expected != actual
                
                errors.add :consistency, "expected #{file} to have #{algo}: #{expected}, actual is #{actual}"
              end
            end
          end
        end
      end

      errors.on(:consistency).nil?
    end

    # Checks for validity against Payload-Oxum
    def valid_oxum?
      bag_info["Payload-Oxum"] == payload_oxum
    end

    protected
    
    # Returns all files in the instance that are not manifested
    def unmanifested_files
      mfs = manifested_files.map { |f| File.join bag_dir, f }
      bag_files.reject { |f| mfs.member? f }
    end

    # Returns a list of manifested files that are not present
    def empty_manifests
      bfs = bag_files
      manifested_files.reject { |f| bfs.member? File.join(bag_dir, f) }
    end
    # Returns a list of tag manifested files that are not present
    def tag_empty_manifests
      empty = []
      tag_manifested_files.each do |f|
        if !File.exists?(File.join(bag_dir,f))
          empty.push f
        end
      end
      return empty
    end
    # Returns a list of all files present in the manifest files
    def manifested_files

      manifest_files.inject([]) do |acc, mf|

        files = File.open(mf) do |io|

          io.readlines.map do |line|
            digest, path = line.chomp.split /\s+/, 2
            decode_filename(path)
          end

        end

        (acc + files).uniq
      end

    end
    # Returns a list of all files in the tag manifest files
    def tag_manifested_files
      tagmanifest_files.inject([]) do |acc, mf|
        files = File.open(mf) do |io|
          io.readlines.map do |line|
            digest, path = line.chomp.split /\s+/, 2
            path
          end
        end
        (acc+files).uniq
      end
    end

  end

end
