require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Module#include" do
  it "calls #append_features(self) in reversed order on each module" do
    $appended_modules = []
    
    m = Module.new do
      def self.append_features(mod)
        $appended_modules << [ self, mod ]
      end
    end
    
    m2 = Module.new do
      def self.append_features(mod)
        $appended_modules << [ self, mod ]
      end
    end

    m3 = Module.new do
      def self.append_features(mod)
        $appended_modules << [ self, mod ]
      end
    end
    
    c = Class.new { include(m, m2, m3) }
    
    $appended_modules.should == [ [ m3, c], [ m2, c ], [ m, c ] ]
  end
  
  it "raises a TypeError when the argument is not a Module" do
    should_raise(TypeError) { ModuleSpecs::Basic.send(:include, Class.new) }
  end
  
  it "should import constants to modules and classes" do
    ModuleSpecs::A.constants.should_include("CONSTANT_A")
    ModuleSpecs::B.constants.should_include("CONSTANT_A","CONSTANT_B")
    ModuleSpecs::C.constants.should_include("CONSTANT_A","CONSTANT_B")
  end

  it "should not override existing constants in modules and classes" do
    ModuleSpecs::A::OVERRIDE.should == :a
    ModuleSpecs::B::OVERRIDE.should == :b
    ModuleSpecs::C::OVERRIDE.should == :c    
  end

  it "should import instance methods to modules and classes" do
    ModuleSpecs::A.instance_methods.should_include("ma")
    ModuleSpecs::B.instance_methods.should_include("ma","mb")
    ModuleSpecs::C.instance_methods.should_include("ma","mb")
  end

  it "should not import methods to modules and classes" do
    ModuleSpecs::A.methods.include?("cma").should == true
    ModuleSpecs::B.methods.include?("cma").should == false
    ModuleSpecs::B.methods.include?("cmb").should == true
    ModuleSpecs::C.methods.include?("cma").should == false    
    ModuleSpecs::C.methods.include?("cmb").should == false
  end
end

describe "Module#include?" do
  it "returns true if the given module is included by self or one of it's ancestors" do
    ModuleSpecs::Super.include?(ModuleSpecs::Basic).should == true
    ModuleSpecs::Child.include?(ModuleSpecs::Basic).should == true
    ModuleSpecs::Child.include?(ModuleSpecs::Super).should == true
    ModuleSpecs::Child.include?(Kernel).should == true
    
    ModuleSpecs::Parent.include?(ModuleSpecs::Basic).should == false
    ModuleSpecs::Basic.include?(ModuleSpecs::Super).should == false
  end
  
  it "raises a TypeError when no module was given" do
    should_raise(TypeError) { ModuleSpecs::Child.include?("Test") }
    should_raise(TypeError) { ModuleSpecs::Child.include?(ModuleSpecs::Parent) }
  end
end
