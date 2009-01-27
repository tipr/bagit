require 'fileutils'

class Bagit

  def initialize(path)
    @source_path = path
  end

  def save(path)
    FileUtils::mkdir path

    data_path = File.join path, 'data'
    FileUtils::mkdir data_path
  end
  
end
