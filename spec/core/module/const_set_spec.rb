require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Module#const_set" do
  it "sets the constant with the given name to the given value" do
    Module.const_set :A, "A"
    Module.const_set :B.to_i, "B"
    Module.const_set "C", "C"
    
    Module.const_get("A").should == "A"
    Module.const_get("B").should == "B"
    Module.const_get("C").should == "C"
  end

  it "raises a NameError when the given name is no valid constant name" do
    should_raise(NameError, "wrong constant name invalid") do
      Module.const_set "invalid", "some value"
    end

    should_raise(NameError, "wrong constant name Dup Dup") do
      Module.const_set "Dup Dup", "some value"
    end

    should_raise(NameError, "wrong constant name 123") do
      Module.const_set "123", "some value"
    end
  end
  
  it "raises a NameError when there is no constant with the given name" do
    should_raise(NameError, "uninitialized constant ModuleSpecs::NotExistant") do
      ModuleSpecs.const_get("NotExistant")
    end
  end

  it "tries to convert the given name to a string using to_str" do
    (o = Object.new).should_receive(:to_str, :returning => "A")
    Module.const_set o, "test"
    Module.const_get(:A).should == "test"
  end
  
  it "raises a TypeError when the given name can't be converted to string using to_str" do
    o = Object.new
    
    should_raise(TypeError, "#{o} is not a symbol") do
      Module.const_set(o, "test")
    end
  
    o.should_receive(:to_str, :returning => 123)
    should_raise(TypeError) do
      Module.const_set(o, "Test")
    end
  end
end
