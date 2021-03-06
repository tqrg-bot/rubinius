require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Bignum#+" do
  before(:each) do
    @bignum = BignumHelper.sbm(76)
  end
  
  it "returns self plus the given Integer" do
    (@bignum + 4).should == 1073741904
    (@bignum + 4.2).should == 1073741904.2
    (@bignum + BignumHelper.sbm(3)).should == 2147483727
  end

  it "raises a TypeError when given a non-Integer" do
    should_raise(TypeError) do
      (obj = Object.new).should_receive(:to_int, :count => 0, :returning => 10)
      @bignum + obj
    end
    
    should_raise(TypeError) do
      @bignum + "10"
    end
    
    should_raise(TypeError) do
      @bignum + :symbol
    end
  end
end
