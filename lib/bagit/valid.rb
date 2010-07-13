require 'rubygems'
require 'validatable'

module BagIt

  class Bag
    include Validatable
    validates_true_for :consistency, :logic => lambda { complete? }
    validates_true_for :completeness, :logic => lambda { consistent? }
  end

  module Validity

    # Return true if the manifest cover all files and all files are
    # covered.
    def complete?

      unmanifested_files.each do |file|
        errors.add :completeness, "#{file} is present but not manifested"
      end

      empty_manifests.each do |file|
        errors.add :completeness, "#{file} is manifested but not present"
      end

      errors.on(:completeness).nil?
    end

    # Return true if all manifested files message digests match.
    def consistent?

      manifest_files.each do |mf|

        # get the algorithm implementation
        File.basename(mf) =~ /^manifest-(.+).txt$/

        algo = case $1
               when /sha1/i
                 Digest::SHA1
               when /md5/i
                 Digest::MD5
               else
                 :unknown
               end

        # Check every file in the manifest
        open(mf) do |io|

          io.each_line do |line|
            expected, path = line.chomp.split /\s+/, 2
            file = File.join(bag_dir, path)

            if File.exist? file
              actual = open(file) { |fio| algo.hexdigest(fio.read) }

              if expected != actual
                errors.add :consistency, "expected #{file} to have #{algo}: #{expected}, actual is #{actual}"
              end

            end
          end

        end

      end

      errors.on(:consistency).nil?
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

    # Returns a list of all files present in the manifest files
    def manifested_files

      manifest_files.inject([]) do |acc, mf|

        files = open(mf) do |io|

          io.readlines.map do |line|
            digest, path = line.chomp.split /\s+/, 2
            path
          end

        end

        (acc + files).uniq
      end

    end

  end

end
