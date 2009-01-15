module TIPRMatchers
  
  class BeInNamespace

    def initialize(expected)
      @expected = expected        # a namespace uri
    end

    def matches?(target)
      @target = target            # a node
      prefix = @target.namespace
      @target_namespace = @target.namespaces[ prefix ? "xmlns:#{prefix}" : 'xmlns']
      @target_namespace == @expected
    end

    def failure_message
      "expected <#{@target_namespace}> to " +
        "the same as <#{@expected}>"
    end

    def negative_failure_message
      "expected <#{@target_namespace}> not to " +
        "the same as <#{@expected}>"
    end

  end

  def be_in_namespace(expected)
    BeInNamespace.new(expected)
  end
  
end
