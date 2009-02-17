module BagIt

  module PackageInfo

    def package_info_txt_file
      File.join bag_dir, 'package-info.txt'
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
    
    def bagit_txt_file
      File.join bag_dir, 'bagit.txt'
    end
    
  end

end
