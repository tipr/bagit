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

    def negative_failure_message
      "expected <#{@target}> to not be in collection <#{@expected}>"
    end

  end

  def be_in(*expected_collection)
    BeIn.new(*expected_collection)
  end

end

Spec::Runner.configure do |config|
  config.include(BagitMatchers)
end
