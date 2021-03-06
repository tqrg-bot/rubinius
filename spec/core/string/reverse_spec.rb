require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes.rb'

describe "String#reverse" do
  it "returns a new string with the characters of self in reverse order" do
    "stressed".reverse.should == "desserts"
    "m".reverse.should == "m"
    "".reverse.should == ""
  end
  
  it "taints the result if self is tainted" do
    "".taint.reverse.tainted?.should == true
    "m".taint.reverse.tainted?.should == true
  end
end

describe "String#reverse!" do
  it "reverses self in place and always returns self" do
    a = "stressed"
    a.reverse!.equal?(a).should == true
    a.should == "desserts"
    
    "".reverse!.should == ""
  end

  compliant :mri, :jruby do
    it "raises a TypeError if self is frozen" do
      "".freeze.reverse! # ok, no change
      should_raise(TypeError) { "anna".freeze.reverse! }
      should_raise(TypeError) { "hello".freeze.reverse! }
    end
  end
end
