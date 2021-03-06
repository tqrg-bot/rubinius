require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Kernel.String" do
  it "converts the given argument to a String by calling #to_s" do
    Kernel.String(nil).should == ""
    Kernel.String("10").should == "10"
    Kernel.String(1.12).should == "1.12"
    Kernel.String(false).should == "false"
    Kernel.String(Object).should == "Object"

    (obj = Object.new).should_receive(:to_s, :returning => "test")
    Kernel.String(obj).should == "test"
  end

# TODO: does not work yet because of undef_method
#
#  it "raises a TypeError of #to_s is not provided" do
#    class << (obj = Object.new)
#      undef_method :to_s
#    end
#    
#    should_raise(TypeError) do
#      Kernel.String(obj)
#    end
#  end
  
  it "raises a TypeError if #to_s does not return a String" do
    (obj = Object.new).should_receive(:to_s, :returning => 123)
    should_raise(TypeError) do
      Kernel.String(obj)
    end
  end
end
