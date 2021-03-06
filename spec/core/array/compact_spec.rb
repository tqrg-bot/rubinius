require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#compact" do
  it "returns a copy of array with all nil elements removed" do
    a = [1, nil, 2, nil, 4, nil]
    a.compact.should == [1, 2, 4]
  end

  it "returns subclass instance for Array subclasses" do
    MyArray[1, 2, 3, nil].compact.class.should == MyArray
  end
end

describe "Array#compact!" do
  it "removes all nil elements" do
    a = ['a', nil, 'b', nil, nil, false, 'c', nil]
    a.compact!.equal?(a).should == true
    a.should == ["a", "b", false, "c"]
  end
  
  it "returns nil if there are no nil elements to remove" do
    [1, 2, false, 3].compact!.should == nil
  end

  compliant :mri do
    it "raises TypeError on a frozen array" do
      should_raise(TypeError) { @frozen_array.compact! }
    end
  end
end
