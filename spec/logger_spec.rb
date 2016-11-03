# coding: utf-8
require 'spec_helper'

describe "logger" do
  it "should let you log through the BagIt module" do
    BagIt::logger.info("this is a string to log")
  end
end

