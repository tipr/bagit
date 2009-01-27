require 'fileutils'

class Bagit

  def initialize(path)
    @source_path = path
  end

  def save(path)
    FileUtils::mkdir path
  end
  
end
