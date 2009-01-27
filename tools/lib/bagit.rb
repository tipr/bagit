require 'fileutils'

class Bagit

  def initialize(path)
    @source_path = path
  end

  def save(path)
    FileUtils::mkdir path
    
    # data dir
    data_path = File.join path, 'data'
    FileUtils::mkdir data_path

    # manifest file
    manifest_path = File.join path, 'manifest-sha1.txt'
    FileUtils.touch manifest_path

    # bagit file
    bagit_txt_path = File.join path, 'bagit.txt'
    open(bagit_txt_path, 'w') do |io|
      io.puts 'line 1'
      io.puts 'line 2'
    end
    
  end
  
end
