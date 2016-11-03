module BagitMatchers

  class BeIn 


    def initialize(*expected_collection)
      @expected = expected_collection
    end

    def matches?(target)
      @target = target
      @expected.include? @target
    end


  end

  def be_in(*expected_collection)
    BeIn.new(*expected_collection)
  end

  class ExistOnFS 


    def matches?(target)
      @target = target
      File.exist? target
    end


  end

  def exist_on_fs 
    ExistOnFS.new
  end

  


end
