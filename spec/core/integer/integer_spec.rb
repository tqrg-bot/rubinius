require File.dirname(__FILE__) + '/../../spec_helper'

describe "Integer#integer?" do
  it "returns true" do
    0.integer?.should == true 
    0xffffffff.integer?.should == true
    -1.integer?.should == true
  end
end
