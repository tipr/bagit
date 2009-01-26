# This module holds a set of helper functions used by scripts and specs
# to manage various parts of constructing the TIPR package

require 'erb'		# ERB for generating our xml files
require 'digest/sha1'	# SHA1 library for calculating checksums

module TIPR

  # Returns xml parsed using a dip object, ERB, and the specified template
  # Template argument should be relative to our template directory
  # FIXME: This is a kludge
  def self.generate_xml(template, dip, rep=nil, orig=nil, active=nil)
    @type = rep if rep	       # Used for typing our template
    @orig = orig if orig       # Used for the tipr envelope
    @active = active if active #  ""
    @dip = dip
    t = open File.join('templates', template) do |io|
      string = io.read
      ERB.new string
    end
    t.result binding
  end
  
  # Creates a simple hash of the input file and sha-1 sum.
  # Intended to facilitate generating and looping through representations.
  def self.sha1_pair(xml)
    {
      :sha_1 => Digest::SHA1.new(xml),
      :xml => xml
    }
  end

end
