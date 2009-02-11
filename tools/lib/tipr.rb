# This module holds a set of helper functions used by scripts and specs
# to manage various parts of constructing the TIPR package

require 'erb'          # ERB for generating our xml files
require 'digest/sha1'  # SHA1 library for calculating checksums
require 'libxml'       # For validating our xml files against schemas

module TIPR

  # Generates xml from the specified template

  def self.gen_xml(template)
    t = open File.join('templates', template) do |io|
      string = io.read
      ERB.new(string, nil, '<>')
    end
    t.result binding
  end

  # Generates representation xml from a template, dip, and the 
  # representation type

  def self.generate_rep(template, dip, rep)
    @dip = dip
    @type = rep
    gen_xml(template)
  end
  
  # Generates the tipr envelope xml from a template, dip, and
  # original and active representations (xml + checksum)
  # In the future, this should be fixed to only require checksums

  def self.generate_tipr_envelope(template, dip, orig, active)
    @dip = dip
    @orig = orig
    @active = active
    gen_xml(template)
  end

  # Generates digiprov xml for a list of events. The oid should
  # be provided when generating digiprov for an entire package
  # in case the set of events is empty
    
  def self.generate_digiprov(template, events, oid=nil)
    @events = events
    @oid = oid if oid
    gen_xml(template)
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
  # LibXML::XML::Schema;
  
  def self.validate(xml_string, schema)

    # parse xml to be validated
    instance = LibXML::XML::Document.string(xml_string)

    # validate
    instance.validate_schema(schema) { yield }
  end

end
