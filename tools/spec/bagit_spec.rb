require 'bagit'

# based on v0.95 http://www.cdlib.org/inside/diglib/bagit/bagitspec.html
describe Bagit do
  it "should be a directory"
  it "should have a sub-directory called data"
  it "should have at least one manifest-[algorithm].txt"
  it "should have a file bagit.txt"
  it "may have zero ormore additional files"
end

describe "bagit.txt" do
  it "should have exaclty two lines"
  it "should have a bagit version"
  it "should have a tag file encoding"
end

describe "manifest-[algorithm].txt" do
  it "should have valid algorithm in the name (at least md5 and sha1)"
  it "should only contain lines of the format CHECKSUM FILENAME"
  it "should only use the slash character as a path separator in FILENAME"
  it "should only use hex-encoded checksums"
  it "should contain FILENAMEs that are relative paths from the base directory"
  it "should have one or more whitespace characters separating fields"
end

describe "fetch.txt" do
  it "should only contain lines of the format URL LENGTH FILENAME"
  it "should only have cannonical URLs"
  it "should only have a positive integer or - (unspecified) for LENGTH"
  it "should only use the slash character as a path separator in FILENAME"
  it "should contain FILENAMEs that are relative paths from the base directory"
  it "should have one or more whitespace characters separating fields"
  it "should be renamed when receipt of a bag is complete"
end

describe "tagmanifest-[algorithm].txt" do
  it "should work just like a nomral manifest file, but only contain tag files"
end

describe "a valid bag" do
  it "should have every present payload file manifested at least once"
  it "should have all manifested files present"
  it "should have verified checksums of all manifested files"
end

describe "bag-info.txt" do
  it "should not be empty"
  it "should contain lines of the format LABEL : VALUE"
  it "should be case insensitive with respect to LABELs"
  it "may have folded VALUEs"
end

describe "serialization" do
  it "should contain only bag"
  it "should have the same basename as the bag's base dir"
  it "should produce a single top level bad dir"
  it "should preserve the validity of the bag"
end

