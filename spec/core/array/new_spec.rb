require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array.new" do
  it "returns a new array when not passed arguments" do
    a = Array.new
    a.class.should == Array
    b = MyArray.new
    b.class.should == MyArray
  end
  
  it "raises ArgumentError when passed a negative size" do
    should_raise(ArgumentError) { Array.new(-1) }
  end
  
  it "returns a new array of size with nil elements" do
    Array.new(5).should == [nil, nil, nil, nil, nil]
    a = MyArray.new(5)
    a.class.should == MyArray
    a.inspect.should == [nil, nil, nil, nil, nil].inspect
  end

  it "calls to_int on size" do
    obj = Object.new
    def obj.to_int() 3 end
    Array.new(obj).should == [nil, nil, nil]
    
    obj = Object.new
    obj.should_receive(:respond_to?, :with => [:to_int], :count => :any, :returning => true)
    obj.should_receive(:method_missing, :with => [:to_int], :returning => 3)
    Array.new(obj).should == [nil, nil, nil]
  end
  
  it "returns a new array of size default objects" do
    Array.new(4, true).should == [true, true, true, true]

    # Shouldn't copy object
    str = "x"
    ary = Array.new(4, str)
    str << "y"
    ary.should == [str, str, str, str]

    a = MyArray.new(4, true)
    a.class.should == MyArray
    a.inspect.should == [true, true, true, true].inspect
  end
  
  it "returns a new array by calling to_ary on an array-like argument" do
    obj = Object.new
    def obj.to_ary() [:foo] end
    Array.new(obj).should == [:foo]
    
    a = MyArray.new(obj)
    a.class.should == MyArray
    a.inspect.should == [:foo].inspect

    obj = Object.new
    obj.should_receive(:respond_to?, :with => [:to_ary], :returning => true, :count => :any)
    obj.should_receive(:method_missing, :with => [:to_ary], :returning => [:foo], :count => :any)
    Array.new(obj).should == [:foo]
  end
  
  it "does not call to_ary on Array subclasses when passed an array-like argument" do
    Array.new(ToAryArray[5, 6, 7]).should == [5, 6, 7]
  end
  
  it "calls to_ary on an argument before to_int" do
    obj = Object.new
    def obj.to_ary() [1, 2, 3] end
    def obj.to_int() 3 end

    Array.new(obj).should == [1, 2, 3]
  end
    
  it "returns an array of size elements from the result of passing each index to block" do
    Array.new(5) { |i| i + 1 }.should == [1, 2, 3, 4, 5]
    
    a = MyArray.new(5) { |i| i + 1 }
    a.class.should == MyArray
    a.inspect.should == [1, 2, 3, 4, 5].inspect
  end  

  it "will fail if a to_ary is supplied as the first argument and a second argument is given" do
    should_raise(TypeError) { Array.new([1, 2], 1) } 
  end
end
