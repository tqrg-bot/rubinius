require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#zip" do
  it "returns an array of arrays containing corresponding elements of each array" do
    [1, 2, 3, 4].zip(["a", "b", "c", "d", "e"]).should ==
      [[1, "a"], [2, "b"], [3, "c"], [4, "d"]]
  end
  
  it "fills in missing values with nil" do
    [1, 2, 3, 4, 5].zip(["a", "b", "c", "d"]).should ==
      [[1, "a"], [2, "b"], [3, "c"], [4, "d"], [5, nil]]
  end
  
  # MRI 1.8.6 uses to_ary, but it's been fixed in 1.9
  compliant(:ruby) do
    it "calls to_ary on its arguments" do
      obj = Object.new
      obj.should_receive(:respond_to?, :with => [:to_ary], :count => :any, :returning => true)
      obj.should_receive(:method_missing, :with => [:to_ary], :returning => [3, 4])
    
      [1, 2].zip(obj).should == [[1, 3], [2, 4]]
    end
  end
  
  compliant(:r19) do
    it "calls to_a on its arguments" do
      [1, 2, 3].zip("f" .. "z", 1 .. 9).should ==
        [[1, "f", 1], [2, "g", 2], [3, "h", 3]]
      
      obj = Object.new
      obj.should_receive(:respond_to?, :with => [:to_a], :count => :any, :returning => true)
      obj.should_receive(:method_missing, :with => [:to_a], :returning => [3, 4])
    
      [1, 2].zip(obj).should == [[1, 3], [2, 4]]
    end
  end

  it "calls block if supplied" do
    values = []
    [1, 2, 3, 4].zip(["a", "b", "c", "d", "e"]) { |value|
      values << value
    }.should == nil
    
    values.should == [[1, "a"], [2, "b"], [3, "c"], [4, "d"]]
  end
  
  it "does not return subclass instance on Array subclasses" do
    MyArray[1, 2, 3].zip(["a", "b"]).class.should == Array
  end
end
