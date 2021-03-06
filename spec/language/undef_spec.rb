require File.dirname(__FILE__) + '/../spec_helper'

class UndefSpecClass
  def meth(other);other;end
end

describe "The undef keyword" do
  it "should undefine 'meth='" do
    obj = UndefSpecClass.new
    (obj.meth 5).should == 5
    class UndefSpecClass
      undef meth
    end
    should_raise(NoMethodError) { obj.meth 5 }
  end
end
