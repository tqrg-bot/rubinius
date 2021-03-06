require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Module#class_variable_defined?" do
  it "returns true if a class variable with the given name is defined in self" do
    c = Class.new { class_variable_set :@@class_var, "test" }
    c.class_variable_defined?(:@@class_var).should == true
    c.class_variable_defined?(:@@class_var.to_i).should == true
    c.class_variable_defined?("@@class_var").should == true
    c.class_variable_defined?(:@@no_class_var).should == false
    c.class_variable_defined?(:@@no_class_var.to_i).should == false
    c.class_variable_defined?("@@no_class_var").should == false
  end
  
  it "raises a NameError when the given name is not allowed" do
    c = Class.new
    
    should_raise(NameError, "`invalid_name' is not allowed as a class variable name") do
      c.class_variable_defined?(:invalid_name)
    end
    
    should_raise(NameError, "`@invalid_name' is not allowed as a class variable name") do
      c.class_variable_defined?("@invalid_name")
    end
  end

  it "converts a non string/symbol/fixnum name to string using to_str" do
    c = Class.new { class_variable_set :@@class_var, "test" }
    (o = Object.new).should_receive(:to_str, :returning => "@@class_var")
    c.class_variable_defined?(o).should == true
  end

  it "raises a TypeError when the given names can't be converted to strings using to_str" do
    c = Class.new { class_variable_set :@@class_var, "test" }
    o = Object.new
    should_raise(TypeError, "#{o} is not a symbol") do
       c.class_variable_defined?(o)
    end
    
    o.should_receive(:to_str, :returning => 123)
    should_raise(TypeError, "Object#to_str should return String") do
      c.class_variable_defined?(o)
    end
  end
end
