require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes.rb'

describe "String#lstrip" do
  it "returns a copy of self with leading whitespace removed" do
   "  hello  ".lstrip.should == "hello  "
   "  hello world  ".lstrip.should == "hello world  "
   "\n\r\t\n\v\r hello world  ".lstrip.should == "hello world  "
   "hello".lstrip.should == "hello"
   "\x00hello".lstrip.should == "\x00hello"
  end
  
  it "taints the result when self is tainted" do
    "".taint.lstrip.tainted?.should == true
    "ok".taint.lstrip.tainted?.should == true
    "   ok".taint.lstrip.tainted?.should == true
  end
end

describe "String#lstrip!" do
  it "modifies self in place and returns self" do
    a = "  hello  "
    a.lstrip!.equal?(a).should == true
    a.should == "hello  "
  end
  
  it "returns nil if no modifications were made" do
    a = "hello"
    a.lstrip!.should == nil
    a.should == "hello"
  end
  
  compliant :mri, :jruby do
    it "raises a TypeError if self is frozen" do
      "hello".freeze.lstrip! # ok, nothing changed
      "".freeze.lstrip! # ok, nothing changed

      should_raise(TypeError) { "  hello  ".freeze.lstrip! }
    end
  end
end
