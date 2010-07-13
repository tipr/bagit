require 'set'

module BagIt

  module Info

    def bag_info_txt_file
      File.join bag_dir, 'bag-info.txt'
    end

    def bag_info
      read_info_file bag_info_txt_file
    end

    def write_bag_info(hash)
      write_info_file bag_info_txt_file, hash
    end

    def bagit_txt_file
      File.join bag_dir, 'bagit.txt'
    end

    def bagit
      read_info_file bagit_txt_file
    end
    
    def write_bagit(hash)
      write_info_file bagit_txt_file, hash
    end

    protected

    def read_info_file(file)
      
      open(file) do |io|
        
        entries = io.read.split /\n(?=[^\s])/
        
        entries.inject({}) do |hash, line|
          name, value = line.chomp.split /\s*:\s*/, 2
          hash.merge({name => value})
        end
        
      end
      
    end

    def write_info_file(file, hash)

      dups = hash.keys.inject(Set.new) do |acc, key|
        a = hash.keys.grep(/#{key}/i)
        acc + (a.size > 1 ? a : [])
      end
      
      raise "Multiple labels (#{dups.to_a.join ', '}) in #{file}" unless dups.empty?
      
      open(file, 'w') do |io|
        
        hash.each do |name, value|
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

  end

end
