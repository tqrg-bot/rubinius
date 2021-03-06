require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/class'

describe "A class definition" do
  it "creates a new class" do
    ClassSpecs::A.class.should == Class
    ClassSpecs::A.new.class.should == ClassSpecs::A
  end
  
  it "has no class variables" do
    ClassSpecs::A.class_variables.should == []
  end
  
  it "has no class-level instance variables" do
    ClassSpecs::A.instance_variables.should == []
  end

  it "allows the declaration of class variables in the body" do
    ClassSpecs::B.class_variables.should == ["@@cvar"]
    ClassSpecs::B.send(:class_variable_get, :@@cvar).should == :cvar
  end
  
  it "allows the declaration of class-level instance variables in the body" do
    ClassSpecs::B.instance_variables.should == ["@ivar"]
    ClassSpecs::B.instance_variable_get(:@ivar).should == :ivar
  end

  it "allows the declaration of class variables in a class method" do
    ClassSpecs::C.class_variables.should == []
    ClassSpecs::C.make_class_variable
    ClassSpecs::C.class_variables.should == ["@@cvar"]
  end
  
  it "allows the declaration of class variables in an instance method" do
    ClassSpecs::D.class_variables.should == []
    ClassSpecs::D.new.make_class_variable
    ClassSpecs::D.class_variables.should == ["@@cvar"]
  end
  
  it "allows the definition of instance methods" do
    ClassSpecs::E.new.meth.should == :meth
  end
  
  it "allows the definition of class methods" do
    ClassSpecs::E.cmeth.should == :cmeth
  end
  
  it "allows the definition of class methods using class << self" do
    ClassSpecs::E.smeth.should == :smeth
  end
  
  it "allows the definition of Constants" do
    Object.const_defined?('CONSTANT').should == false
    ClassSpecs::E.const_defined?('CONSTANT').should == true
    ClassSpecs::E::CONSTANT.should == :constant!
  end
  
  it "returns the value of the last statement in the body" do
    class ClassSpecs::Empty; end.should == nil
    class ClassSpecs::Twenty; 20; end.should == 20
    class ClassSpecs::Plus; 10 + 20; end.should == 30
    class ClassSpecs::Singleton; class << self; :singleton; end; end.should == :singleton
  end
end

describe "An outer class definition" do
  it "contains the inner classes" do
    ClassSpecs::Container.constants.should_include('A', 'B')
  end
end

describe "A Class Definitions extending an object" do
  it "allows adding methods" do
    ClassSpecs::O.smeth.should == :smeth
  end
  
  it "should raise a TypeError when trying to extend numbers" do
    should_raise(TypeError) do
      eval <<-CODE
        class << 1
          def xyz
            self
          end
        end
      CODE
    end
  end
end

describe "Reopening a class" do
  it "extends the previous definitions" do
    c = ClassSpecs::F.new
    c.meth.should == :meth
    c.another.should == :another
  end
  
  it "overwrites existing methods" do
    ClassSpecs::G.new.override.should == :override
  end
  
  it "raises a TypeError when superclasses mismatch" do
    should_raise(TypeError) { class ClassSpecs::A < Array; end }
  end
end

describe "class provides hooks" do
  it "calls inherited when a class is created" do
    ClassSpecs::Subclasses.should == [ClassSpecs::K]
  end
end

