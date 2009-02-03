require 'open-uri'
require 'digest/sha1'
require 'fileutils'

class String

  def wrap(width)
    s = gsub(/\s+/, ' ').strip

    if s.length > width
      s[0...width] + '\n' + s[width..-1].wrap(width)
    else
      s
    end

  end

  def indent(n)
    indent = ' ' * n
    gsub '\n', "\n#{indent}"
  end

end

module Bagit

  VERSION = '0.95'

  class Bag

    attr_reader :bag_path

    def initialize(path)
      @bag_path = path

      # make the dir structure if it doesn't exist
      FileUtils::mkdir @bag_path unless File.directory? @bag_path
      FileUtils::mkdir_p data_dir unless File.directory? data_dir

      # write the bagit.txt
      open(bagit_txt_file, 'w') do |io|
        io.puts "BagIt-Version: #{VERSION}"
        io.puts 'Tag-File-Character-Encoding: UTF-8'
      end

      # write the package-info.txt
      set_package_info 'Packing-Software', "Bagit ruby gem (http://github.com/flazz/tipr)"
    end

    def package_info_txt_file
      File.join @bag_path, 'package-info.txt'
    end

    def data_dir
      File.join @bag_path, 'data'
    end

    def data_files
      pattern = File.join data_dir, '**'
      Dir[pattern].select { |f| File.file? f }
    end

    def bagit_txt_file
      File.join @bag_path, 'bagit.txt'
    end

    def manifest_files
      pattern = File.join @bag_path, "manifest-*.txt"
      Dir[pattern]
    end

    def manifest_file(algorithm='sha1')
      File.join @bag_path, "manifest-#{algorithm}.txt"
    end

    def add_file(base_path)
      path = File.join(data_dir, base_path)
      raise "Bag file exists #{base_path}" if File.exist? path
      open(path, 'w') { |io| yield io }
      digest = open(path) { |io| Digest::SHA1.hexdigest io.read }
      open(manifest_file, 'a') { |io| io.puts "#{digest} #{path}" }
    end

    def fetch_txt_file
      File.join @bag_path, 'fetch.txt'
    end

    def add_remote_file(url, path, size=nil)
      open(fetch_txt_file, 'a') do |io|
        io.puts "#{url} #{size || '-'} #{path}"
      end
    end

    # fet all remote files
    def fetch!

      # too many nests, not enough whitespace, i know, but it would
      # double the size of this block and be less readable, maybe if
      # ruby would support currying or something it would be
      # nicer. besides i'm used to reading lisp now.
      open(fetch_txt_file) do |io|
        io.readlines.each do |line|
          (url, length, path) = line.chomp.split(/\s+/, 3)
          self.add_file(path) do |io|
            io.write open(url)
          end
        end
      end

      # rename the old ones
      Dir["#{fetch_txt_file}.?*"].sort.reverse.each do |f|
        if f =~ /fetch.txt.(\d+)$/
          new_f = File.join File.dirname(f), "fetch.txt.#{$1.to_i + 1}"
          FileUtils::mv f, new_f
        end
      end

      # move the current fetch_txt
      FileUtils::mv fetch_txt_file, "#{fetch_txt_file}.0"
    end

    def read_package_info
      open(package_info_txt_file) do |io|
        entries = io.read.split /\n(?=[^\s])/
        entries.inject({}) do |hash, line|
          name, value = line.chomp.split /\s*:\s*/
          hash.merge({name => value})
        end
      end
    end

    def save_package_info(info)
      open(package_info_txt_file, 'w') do |io|
        info.each do |name, value|
          simple_entry = "#{name}: #{value.gsub /\s+/, ' '}"
          entry = if simple_entry.length > 79
                    simple_entry.wrap(77).indent(2)
                  else
                    simple_entry
                  end

          io.puts entry
        end
      end
    end

    def set_package_info(name, value)
      name = name.split('-').map { |t| t.capitalize }.join '-'
      info = if File.exist? package_info_txt_file
               read_package_info
             else
               {}
             end

      info[name] = value
      save_package_info(info)
    end

    def valid?
      complete? && fixed?
    end

    # Returns true if all files in the bag are manifested and if all
    # manifestations are present in the bag
    def complete?

      # all files that are manifested
      all_files_manifested = data_files.all? do |f|
        md = manifested_digests(f)
        !md.empty? && md.all? { |algorithm, value| value != nil }
      end

      # every file that is manifested
      manifested_files = manifest_files.inject([]) do |acc,mf|
        open(mf) do |io|
          acc + io.readlines.map do |line|
            line.chomp.split(/\s+/)[1]
          end
        end
      end

      all_files_manifested && manifested_files.all? { |m| data_files.include? m }
    end

    # Returns true if all present manifested files' message digests
    # match the actual message digest
    def fixed?
      data_files.all? do |f|
        data = open(f) { |io| io.read }
        manifested_digests(f).all? do |algorithm, value|
          actual = case algorithm
                   when :sha1
                     Digest::SHA1.hexdigest data
                   when :md5
                     Digest::MD5.hexdigest data
                   else
                     :unknown
                   end

          actual == value || actual == :unknown
        end
      end
    end


    protected

    def manifested_digests(f)
      manifest_files.inject({}) do |acc,mf|
        mf =~ /manifest-(.+)\.txt$/
        algorithm = $1
        expected_digest = open(mf) do |io|
          match = io.readlines.find { |line| line.include? f }
          match.split(/\s+/)[0] rescue nil
        end
        acc.merge({algorithm.intern => expected_digest})
      end
    end

  end

end

