require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#concat" do
  it "appends the elements in the other array" do
    ary = [1, 2, 3]
    ary.concat([9, 10, 11]).equal?(ary).should == true
    ary.should == [1, 2, 3, 9, 10, 11]
    ary.concat([])
    ary.should == [1, 2, 3, 9, 10, 11]
  end
  
  it "does not loop endlessly when argument is self" do
    ary = ["x", "y"]
    ary.concat(ary).should == ["x", "y", "x", "y"]
  end  

  it "calls to_ary on its argument" do
    obj = Object.new
    def obj.to_ary() ["x", "y"] end
    [4, 5, 6].concat(obj).should == [4, 5, 6, "x", "y"]
    
    obj = Object.new
    obj.should_receive(:respond_to?, :with => [:to_ary], :count => :any, :returning => true)
    obj.should_receive(:method_missing, :with => [:to_ary], :returning => [:x])
    [].concat(obj).should == [:x]
  end
  
  it "does not call to_ary on array subclasses" do
    [].concat(ToAryArray[5, 6, 7]).should == [5, 6, 7]
  end
  
  compliant :mri do
    it "raises a TypeError when Array is frozen and modification occurs" do
      should_raise(TypeError) { @frozen_array.concat [1] }
    end

    it "does not raise a TypeError when Array is frozen but no modification occurs" do
      @frozen_array.concat [] # ok, no modification
    end
  end
end
