# This module holds a set of helper functions used by scripts and specs
# to manage various parts of constructing the TIPR package

require 'erb'          # ERB for generating our xml files
require 'digest/sha1'  # SHA1 library for calculating checksums
require 'libxml'       # For validating our xml files against schemas

module TIPR

  # Returns xml parsed using a dip object, ERB, and the specified template
  # Template argument should be relative to our template directory
  # FIXME: This is a kludge

  def self.generate_xml(template, dip, rep=nil, orig=nil, active=nil, events=nil, oid=nil)
    @type = rep if rep         # Used for typing our template
    @orig = orig if orig       # Used for the tipr envelope
    @active = active if active #  ""
    @dip = dip
    @events = events
    @oid = oid
    t = open File.join('templates', template) do |io|
      string = io.read
      ERB.new(string, nil, '<>')
    end
    t.result binding
  end
  
  # Creates a simple hash of the input file and sha-1 sum.
  # Intended to facilitate generating and looping through representations.

  def self.sha1_pair(xml)
    {
      :sha_1 => Digest::SHA1.hexdigest(xml),
      :xml => xml
    }
  end
  
  # Validate an xml file against a schema. Schema must be a 
  # LibXML::XML::Schema; xml_file is a path to a file
  
  def self.validates?(xml_string, schema)

    # parse xml to be validated
    instance = LibXML::XML::Document.string(xml_string)

    # validate
    instance.validate_schema(schema)
  end

end
