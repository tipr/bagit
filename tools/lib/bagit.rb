require 'open-uri'
require 'digest/sha1'
require 'fileutils'

class Bagit

  VERSION = '0.95'

  attr_reader :path

  def initialize(path)
    @path = path

    # make the dir structure
    FileUtils::mkdir @path
    FileUtils::mkdir data_dir

    # write the bagit.txt
    open(bagit_txt_file, 'w') do |io|
      io.puts "BagIt-Version: #{VERSION}"
      io.puts 'Tag-File-Character-Encoding: UTF-8'
    end
    
    # write the package-info.txt
    set_package_info 'Packing-Software', "Bagit ruby gem (http://github.com/flazz/tipr)"
    
  end

  def package_info_txt_file
    File.join @path, 'package-info.txt'
  end
  
  def data_dir
    File.join @path, 'data'
  end

  def data_files
    pattern = File.join data_dir, '**'
    Dir[pattern].select { |f| File.file? f }
  end

  def bagit_txt_file
    File.join @path, 'bagit.txt'
  end

  def manifest_file(algorithm='sha1')
    File.join @path, "manifest-#{algorithm}.txt"
  end

  def add_file(base_path)
    path = File.join(data_dir, base_path)

    # write the data file
    open(path, 'w') do |io|
      yield io
    end

    # add an entry to the manifest file
    open(manifest_file, 'a') do |mio|

      data_files.map do |file_path|
        digest = open(file_path) { |fio| Digest::SHA1.hexdigest fio.read }
        mio.puts "#{digest} #{path}"
      end

    end

  end

  def fetch_txt_file
    File.join @path, 'fetch.txt'
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
      io.readlines.inject({}) do |hash, line|
        name, value = line.chomp.split /\s*:\s*/
        hash.merge({name => value})
      end
    end
  end
  
  def save_package_info(info)
    open(package_info_txt_file, 'w') do |io|
      info.each do |name, value|
        io.puts "#{name}: #{value}"
      end
    end
  end
  
  def set_package_info(name, value)
    name = name.split('-').map { |t| t. capitalize }.join '-'
    
    info = if File.exist? package_info_txt_file
             read_package_info
           else
             {}
           end
    
    info[name] = value
    save_package_info(info)
  end
  
end
