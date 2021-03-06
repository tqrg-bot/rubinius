require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Struct.new" do
  it "creates a constant in Struct namespace with string as first argument" do
    struct = Struct.new('Animal', :name, :legs, :eyeballs)
    struct.should == Struct::Animal
  end

  it "overwrites previously defined constants with string as first argument" do
    first = Struct.new('Person', :height, :weight)
    first.should == Struct::Person

    old, $VERBOSE = $VERBOSE, nil
    second = Struct.new('Person', :hair, :sex)
    second.should == Struct::Person
    $VERBOSE = old

    first.members.should_not == second.members
  end

  it "calls to_str on its first argument (constant name)" do
    obj = Object.new
    def obj.to_str() "Foo" end
    struct = Struct.new(obj)
    struct.should == Struct::Foo
  end

  it "accepts nil first argument for not creating constants" do
    Struct.new(nil, :foo).new("bar").foo.should == "bar"
  end

  it "does not create a constant with symbol as first argument" do
    struct = Struct.new(:Animal, :name, :legs, :eyeballs)
    struct.should_not == Struct::Animal
  end

  it "creates a new anonymous class with symbol arguments" do
    Struct.new(:make, :model).class.should == Class
  end

  it "fails with invalid constant name as first argument" do
    should_raise(NameError) { Struct.new('animal', :name, :legs, :eyeballs) }
  end

  it "raises TypeError if object doesn't respond to to_sym" do
    should_raise(TypeError) { Struct.new(:animal, 1.0) }
    should_raise(TypeError) { Struct.new(:animal, Time.now) }
    should_raise(TypeError) { Struct.new(:animal, Class) }
    should_raise(TypeError) { Struct.new(:animal, nil) }
    should_raise(TypeError) { Struct.new(:animal, true) }
    should_raise(TypeError) { Struct.new(:animal, ['chris', 'evan']) }
    should_raise(TypeError) { Struct.new(:animal, { :name => 'chris' }) }
  end

  it "raises TypeError if object is not a Symbol" do
    obj = Object.new
    def obj.to_sym() :ruby end
    should_raise(TypeError) { Struct.new(:animal, obj) }
  end

  it "accepts Fixnums as Symbols unless fixnum.to_sym.nil?" do
    old, $VERBOSE = $VERBOSE, nil
    num = :foo.to_i
    Struct.new(nil, num).new("bar").foo.should == "bar"
    $VERBOSE = old
  end

  it "raises ArgumentError if fixnum#to_sym is nil" do
    old, $VERBOSE = $VERBOSE, nil
    num = 10000
    num.to_sym.should == nil  # if this fails, we need a new Fixnum to test
    should_raise(ArgumentError) { Struct.new(:animal, num) }
    $VERBOSE = old
  end

  it "instance_eval's a passed block" do
    klass = Struct.new(:something) { @something_else = 'something else entirely!' }
    klass.instance_variables.should_include '@something_else'
  end

  it "creates a constant in subclass' namespace" do
    struct = Apple.new('Computer', :size)
    struct.should == Apple::Computer
  end

  it "creates an instance" do
    Struct::Ruby.new.kind_of?(Struct::Ruby).should == true
  end

  it "creates reader methods" do
    Struct::Ruby.new.methods.should_include 'version'
    Struct::Ruby.new.methods.should_include 'platform'
  end

  it "creates writer methods" do
    Struct::Ruby.new.methods.should_include 'version='
    Struct::Ruby.new.methods.should_include 'platform='
  end

  it "fails with too many arguments" do
    should_raise(ArgumentError) { Struct::Ruby.new('2.0', 'i686', true) }
  end
end
