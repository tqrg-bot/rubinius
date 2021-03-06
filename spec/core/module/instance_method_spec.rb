require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Module#instance_method" do
  it "returns an UnboundMethod representing the instance method with the given name" do
    c = Class.new do
      def test
        "test"
      end
    end
    
    meth = c.instance_method(:test)
    meth.inspect.should == "#<UnboundMethod: #{c}#test>"

    meth = c.instance_method("test")
    meth.inspect.should == "#<UnboundMethod: #{c}#test>"
    
    meth = Object.instance_method("dup")
    meth.inspect.should == "#<UnboundMethod: Object(Kernel)#dup>"
  end
  
  it "raises a TypeError if the given name is not a string/symbol" do
    should_raise(TypeError) do
      Object.instance_method(Object.new)
    end
  end
end
