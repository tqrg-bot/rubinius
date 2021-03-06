require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#<=>" do
  it "calls <=> left to right and return first non-0 result" do
    [-1, +1, nil, "foobar"].each do |result|
      lhs = Array.new(3) { Object.new }
      rhs = Array.new(3) { Object.new }
    
      lhs[0].should_receive(:<=>, :with => [rhs[0]], :returning => 0)
      lhs[1].should_receive(:<=>, :with => [rhs[1]], :returning => result)
      lhs[2].should_not_receive(:<=>)

      (lhs <=> rhs).should == result
    end
  end
  
  it "returns 0 if the arrays are equal" do
    ([] <=> []).should == 0
    ([1, 2, 3, 4, 5, 6] <=> [1, 2, 3, 4, 5.0, 6.0]).should == 0
  end
  
  it "returns -1 if the array is shorter than the other array" do
    ([] <=> [1]).should == -1
    ([1, 1] <=> [1, 1, 1]).should == -1
  end

  it "returns +1 if the array is longer than the other array" do
    ([1] <=> []).should == +1
    ([1, 1, 1] <=> [1, 1]).should == +1
  end

  it "calls to_ary on its argument" do
    obj = Object.new
    def obj.to_ary() [1, 2, 3] end
    ([4, 5] <=> obj).should == ([4, 5] <=> obj.to_ary)
    
    obj = Object.new
    obj.should_receive(:respond_to?, :with => [:to_ary], :count => :any, :returning => true)
    obj.should_receive(:method_missing, :with => [:to_ary], :returning => [4, 5])
    ([4, 5] <=> obj).should == 0
  end

  it "does not call to_ary on array subclasses" do
    ([5, 6, 7] <=> ToAryArray[5, 6, 7]).should == 0
  end
end
