require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Module#method_defined?" do
  it "returns true if a public or private method with the given name is defined in self, self's ancestors or one of self's included modules" do
    # Defined in Child
    ModuleSpecs::Child.method_defined?(:public_child).should == true
    ModuleSpecs::Child.method_defined?(:protected_child.to_i).should == true
    ModuleSpecs::Child.method_defined?("private_child").should == false

    # Defined in Parent
    ModuleSpecs::Child.method_defined?("public_parent").should == true
    ModuleSpecs::Child.method_defined?(:protected_parent.to_i).should == true
    ModuleSpecs::Child.method_defined?(:private_parent).should == false

    # Defined in Module
    ModuleSpecs::Child.method_defined?(:public_module).should == true
    ModuleSpecs::Child.method_defined?(:protected_module).should == true
    ModuleSpecs::Child.method_defined?(:private_module).should == false

    # Defined in SuperModule
    ModuleSpecs::Child.method_defined?(:public_super_module).should == true
    ModuleSpecs::Child.method_defined?(:protected_super_module).should == true
    ModuleSpecs::Child.method_defined?(:private_super_module).should == false
  end

  it "raises a TypeError when the given object is not a string/symbol/fixnum" do
    c = Class.new
    o = Object.new
    
    should_raise(TypeError, "#{o} is not a symbol") do
      c.method_defined?(o)
    end
    
    o.should_receive(:to_str, :returning => 123)
    should_raise(TypeError, "Object#to_str should return String") do
      c.method_defined?(o)
    end
  end
  
  it "converts the given name to a string using to_str" do
    c = Class.new { def test(); end }
    (o = Object.new).should_receive(:to_str, :returning => "test")
    
    c.method_defined?(o).should == true
  end
end
