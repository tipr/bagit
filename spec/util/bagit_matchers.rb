module BagitMatchers

  class BeIn

    def initialize(*expected_collection)
      @expected = expected_collection
    end

    def matches?(target)
      @target = target
      @expected.include? @target
    end

    def failure_message
      "expected <#{@target}> to be in collection <#{@expected}>"
    end

    def failure_message_when_negated
      "expected <#{@target}> to not be in collection <#{@expected}>"
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

    def failure_message
      "expected <#{@target}> to exist, but it doesn't"
    end

    def failure_message_when_negated
      "expected <#{@target}> to not exist but it does"
    end

  end

  def exist_on_fs
    ExistOnFS.new
  end

  class BeADirectory

    def matches?(target)
      @target = target
      File.directory? target
    end

    def failure_message
      "expected <#{@target}> to be a directory, but it isn't"
    end

    def failure_message_when_negated
      "expected <#{@target}> not to be a directory, but it is"
    end

  end

  def be_a_directory
    BeADirectory.new
  end

end
