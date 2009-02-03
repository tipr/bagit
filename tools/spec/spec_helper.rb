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
      "expected <#{@target_namespace}> to be " +
        "the same as <#{@expected}>"
    end

    def negative_failure_message
      "expected <#{@target_namespace}> not to be " +
        "the same as <#{@expected}>"
    end

  end

  class ReferenceAFile

    # Assume an XML file, unless otherwise specified.
    def initialize(pattern=/\.xml\Z/i, type='XML')  
      @pattern = pattern        # The REGEX we're searching for
      @type = type              # A pretty name to describe the file type
    end

    def matches?(target)
      @target = target          # a node with an href
      return false if not @target
      
      @ref = @target['href']
      return false if not @ref
      
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

  class HaveXPath

    def initialize(xpath, ns)  
      @xpath = xpath            # The XPath we would like to match.
      @ns = ns                  # The namespace to use
    end

    def matches?(target)
      @target = target          # a node that should contain the xpath
      not @target.xpath(@xpath, @ns).empty?
    end

    def failure_message
      "expected xpath <#{@xpath}> to be in " +
        "node <#{@target}>"
    end

    def negative_failure_message
      "expected xpath <#{@xpath}> not to be " +
        "in node <#{@target}>"
    end

  end
  
  class HaveNodeContent

    def initialize(content)  
      @content = content        # Content: either an array or a single value
    end

    def matches?(target)
      @target = target          # a NodeSet that should have matching content
      node_content = @target.map { |n| n.content.strip }
      return node_content == @content if @content.is_a?(Array)
      node_content.uniq == [@content]
    end

    def failure_message
      "expected NodeSet <#{@target}> to have content " +
        "<#{@values}>"
    end

    def negative_failure_message
      "expected NodeSet <#{@target}> not to have " +
        "content <#{@values}>"
    end

  end
  
  def have_node_content(values)
    HaveNodeContent.new(values)
  end
  
  def have_xpath(xpath, ns)
    HaveXPath.new(xpath, ns)
  end

  def reference_an_xml_file()
    ReferenceAFile.new()
  end

  def reference_a_file()
    ReferenceAFile.new(/.+/, 'UNRESTRICTED TYPE OF')
  end

  def be_in_namespace(expected)
    BeInNamespace.new(expected)
  end
  
end

Spec::Runner.configure do |config|  
  config.include(TIPRMatchers)
end  
