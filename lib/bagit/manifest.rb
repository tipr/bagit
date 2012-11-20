require 'pathname'
require 'digest/sha1'
require 'digest/md5'

module BagIt

  # Requires response to bag_dir, tag_files, bag_files
  module Manifest

    # All tag files that are bag manifest files (manifest-[algorithm].txt)
    def manifest_files
      tag_files.select { |f| File.basename(f) =~ /^manifest-.*.txt/ }
    end

    # A path to a manifest file of the specified algorithm
    def manifest_file(algo)
      File.join bag_dir, "manifest-#{algo}.txt"
    end

    # Generate manifest files for all the bag files
    def manifest!

      # nuke all the existing manifest files
      manifest_files.each { |f| FileUtils::rm f }

      # manifest each tag file for each algorithm
      bag_files.each do |f|
        rel_path = Pathname.new(f).relative_path_from(Pathname.new(bag_dir)).to_s

        # sha1
        sha1 = Digest::SHA1.file f
        open(manifest_file(:sha1), 'a') { |io| io.puts "#{sha1} #{rel_path}" }

        # md5
        md5 = Digest::MD5.file f
        open(manifest_file(:md5), 'a') { |io| io.puts "#{md5} #{rel_path}" }
      end

    end

    # All tag files that are bag manifest files (tagmanifest-[algorithm].txt)
    def tagmanifest_files
      files = Dir[File.join(@bag_dir, '*')].select { |f|
        File.file? f and File.basename(f) =~ /^tagmanifest-.*.txt/ 
      }
    end

    # A path to a tagmanifest file of the specified algorithm
    def tagmanifest_file(algo)
      File.join bag_dir, "tagmanifest-#{algo}.txt"
    end

    # Generate manifest files for all the tag files (except the tag
    # manifest files)
    def tagmanifest!

      # nuke all the existing tagmanifest files
      tagmanifest_files.each { |f| FileUtils::rm f }

      # manifest each (non tagmanifest) tag file for each algorithm
      (tag_files - tagmanifest_files).each do |f|
        data = open(f) { |io| io.read }
        rel_path = Pathname.new(f).relative_path_from(Pathname.new(bag_dir)).to_s

        # sha1
        sha1 = Digest::SHA1.hexdigest data
        open(tagmanifest_file(:sha1), 'a') { |io| io.puts "#{sha1} #{rel_path}" }

        # md5
        md5 = Digest::MD5.hexdigest data
        open(tagmanifest_file(:md5), 'a') { |io| io.puts "#{md5} #{rel_path}" }
      end

    end

    # Returns true if all present manifested files' message digests
    # match the actual message digest
    def fixed?
      (manifest_files + tagmanifest_files).all? do |mf|
        # extract the algorithm
        mf =~ /manifest-(.+).txt$/

        algo = case $1
               when /sha1/i
                 Digest::SHA1
               when /md5/i
                 Digest::MD5
               else
                 :unknown
               end

        # check it, an unknown algorithm is always true
        unless algo == :unknown
          lines = open(mf) { |io| io.readlines }

          lines.all? do |line|
            manifested_digest, path = line.chomp.split /\s+/, 2
            actual_digest = open(File.join(@bag_dir, path)) { |io| algo.hexdigest io.read }
            actual_digest == manifested_digest
          end

        else
          true
        end

      end

    end

  end

end
