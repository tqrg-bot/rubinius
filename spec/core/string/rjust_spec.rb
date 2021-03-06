require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes.rb'

describe "String#rjust with length, padding" do
  it "returns a new string of specified length with self right justified and padded with padstr" do
    "hello".rjust(20, '1234').should == "123412341234123hello"

    "".rjust(1, "abcd").should == "a"
    "".rjust(2, "abcd").should == "ab"
    "".rjust(3, "abcd").should == "abc"
    "".rjust(4, "abcd").should == "abcd"
    "".rjust(6, "abcd").should == "abcdab"

    "OK".rjust(3, "abcd").should == "aOK"
    "OK".rjust(4, "abcd").should == "abOK"
    "OK".rjust(6, "abcd").should == "abcdOK"
    "OK".rjust(8, "abcd").should == "abcdabOK"
  end
  
  it "pads with whitespace if no padstr is given" do
    "hello".rjust(20).should == "               hello"
  end

  it "returns self if it's longer than or as long as the specified length" do
    "".rjust(0).should == ""
    "".rjust(-1).should == ""
    "hello".rjust(4).should == "hello"
    "hello".rjust(-1).should == "hello"
    "this".rjust(3).should == "this"
    "radiology".rjust(8, '-').should == "radiology"
  end

  it "taints result when self or padstr is tainted" do
    "x".taint.rjust(4).tainted?.should == true
    "x".taint.rjust(0).tainted?.should == true
    "".taint.rjust(0).tainted?.should == true
    "x".taint.rjust(4, "*").tainted?.should == true
    "x".rjust(4, "*".taint).tainted?.should == true
  end

  it "tries to convert length to an integer using to_int" do
    "^".rjust(3.8, "^_").should == "^_^"
    
    obj = Object.new
    def obj.to_int() 3 end
      
    "o".rjust(obj, "o_").should == "o_o"
    
    obj = Object.new
    obj.should_receive(:respond_to?, :with => [:to_int], :count => :any, :returning => true)
    obj.should_receive(:method_missing, :with => [:to_int], :returning => 3)
    "~".rjust(obj, "~_").should == "~_~"
  end
  
  it "raises a TypeError when length can't be converted to an integer" do
    should_raise(TypeError) { "hello".rjust("x") }
    should_raise(TypeError) { "hello".rjust("x", "y") }
    should_raise(TypeError) { "hello".rjust([]) }
    should_raise(TypeError) { "hello".rjust(Object.new) }
  end

  it "tries to convert padstr to a string using to_str" do
    padstr = Object.new
    def padstr.to_str() "123" end
    
    "hello".rjust(10, padstr).should == "12312hello"

    obj = Object.new
    obj.should_receive(:respond_to?, :with => [:to_str], :count => :any, :returning => true)
    obj.should_receive(:method_missing, :with => [:to_str], :returning => "k")

    "hello".rjust(7, obj).should == "kkhello"
  end

  it "raises a TypeError when padstr can't be converted" do
    should_raise(TypeError) do
      "hello".rjust(20, :sym)
    end
    
    should_raise(TypeError) do
      "hello".rjust(20, ?c)
    end
    
    should_raise(TypeError) do
      "hello".rjust(20, Object.new)
    end
  end
  
  it "raises an ArgumentError when padstr is empty" do
    should_raise(ArgumentError) do
      "hello".rjust(10, '')
    end
  end
  
  it "returns subclass instances when called on subclasses" do
    MyString.new("").rjust(10).class.should == MyString
    MyString.new("foo").rjust(10).class.should == MyString
    MyString.new("foo").rjust(10, MyString.new("x")).class.should == MyString
    
    "".rjust(10, MyString.new("x")).class.should == String
    "foo".rjust(10, MyString.new("x")).class.should == String
  end
end
