require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Bignum#<<" do
  before(:each) do
    @bignum = BignumHelper.sbm(9)
  end
  
  it "returns self shifted the given amount of bits to the left" do
    (@bignum << 4).should == 17179869328
    (@bignum << 9).should == 549755818496
  end

  it "performs a right-shift if given a negative value" do
    (@bignum << -2).should == (@bignum >> 2)
    (@bignum << -4).should == (@bignum >> 4)
  end

  it "tries to convert its argument to an Integer using to_int" do
    (@bignum << 4.5).should == 17179869328
    
    (obj = Object.new).should_receive(:to_int, :returning => 4)
    (@bignum << obj).should == 17179869328
  end

  it "raises a TypeError when the given argument can't be converted to Integer" do
    obj = Object.new
    should_raise(TypeError) { @bignum << obj }
    
    obj.should_receive(:to_int, :returning => "asdf")
    should_raise(TypeError) { @bignum << obj }
  end
end
