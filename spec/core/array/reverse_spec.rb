require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#reverse" do
  it "returns a new array with the elements in reverse order" do
    [].reverse.should == []
    [1, 3, 5, 2].reverse.should == [2, 5, 3, 1]
  end

  it "returns subclass instance on Array subclasses" do
    MyArray[1, 2, 3].reverse.class.should == MyArray
  end
end

describe "Array#reverse!" do
  it "reverses the elements in place" do
    a = [6, 3, 4, 2, 1]
    a.reverse!.equal?(a).should == true
    a.should == [1, 2, 4, 3, 6]
    [].reverse!.should == []
  end

  compliant :mri do
    it "raises TypeError on a frozen array" do
      should_raise(TypeError) { @frozen_array.reverse! }
    end
  end
end
