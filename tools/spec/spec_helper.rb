module TIPRMatchers
  
  class BeInNamespace

    def initialize(expected)
      @expected = expected        # a namespace uri
    end

    def matches?(target)
      @target = target            # a node
      prefix = @target.namespace
      @target_namespace = @target.namespaces[ prefix ? "xmlns:#{prefix}" : 'xmlns' ]
      @target_namespace == @expected
    end

    def failure_message
      "expected <#{@target_namespace}> to be" +
        "the same as <#{@expected}>"
    end

    def negative_failure_message
      "expected <#{@target_namespace}> not to be" +
        "the same as <#{@expected}>"
    end

  end

  class ReferenceAFile

    # Assume an XML file, unless otherwise specified.
    def initialize(pattern=/\.xml\Z/i, type='XML')  
      @pattern = pattern        # The REGEX we're searching for
      @type = type		# A pretty name to describe the file type
    end

    def matches?(target)
      @target = target          # a node with an href
      if @target == nil
        return false
      end
      @ref = @target['href']
      if @ref == nil 
        return false
      end	
      @ref.match(@pattern) != nil
    end

    def failure_message
      "expected <#{@ref}> to be " +
        "a(n) <#{@type}> file"
    end

    def negative_failure_message
      "expected <#{@ref}> not to be " +
        "a(n) <#{@type}> file"
    end

  end

  def reference_an_xml_file()
    ReferenceAFile.new()
  end

  def be_in_namespace(expected)
    BeInNamespace.new(expected)
  end
  
end

Spec::Runner.configure do |config|  
  config.include(TIPRMatchers)
end  
