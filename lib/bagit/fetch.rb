require 'open-uri'

module BagIt
  
  module Fetch
    
    def fetch_txt_file
      File.join @bag_dir, 'fetch.txt'
    end

    def add_remote_file(url, path, size, sha1, md5)
      if path =~ /^data\//
        open(fetch_txt_file, 'a') { |io| io.puts "#{url} #{size || '-'} #{path}" }
        open(manifest_file('sha1'), 'a') { |io| io.puts "#{sha1} #{File.join path}" }
        open(manifest_file('md5'), 'a') { |io| io.puts "#{md5} #{File.join path}" }
      end
    end

    # fetch all remote files
    def fetch!

      open(fetch_txt_file) do |io|
        
        io.readlines.each do |line|
          
          (url, length, path) = line.chomp.split(/\s+/, 3)

          if path =~ /^data\//
            path.gsub!(/^data\//, '')
            add_file(path) do |io|
              io.write open(url)
            end
          end
          
        end
        
      end

      # rename the old fetch.txt
      Dir["#{fetch_txt_file}.?*"].sort.reverse.each do |f|
        
        if f =~ /fetch.txt.(\d+)$/
          new_f = File.join File.dirname(f), "fetch.txt.#{$1.to_i + 1}"
          FileUtils::mv f, new_f
        end
        
      end

      # move the current fetch_txt
      FileUtils::mv fetch_txt_file, "#{fetch_txt_file}.0"
    end
    
  end
  
end
