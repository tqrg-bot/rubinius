require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Bignum#**" do
  before(:each) do
    @bignum = BignumHelper.sbm(47)
  end
  
  it "returns self raised to other power" do
    (@bignum ** 4).should == 1329228228517658539377366716859970881
    (@bignum ** 5.2).inspect.should == "9.13438731244363e+46"
  end

  it "raises a TypeError when given a non-Integer" do
    should_raise(TypeError) do
      (obj = Object.new).should_receive(:to_int, :count => 0, :returning => 10)
      @bignum ** obj
    end
    
    should_raise(TypeError) do
      @bignum ** "10"
    end

    should_raise(TypeError) do
      @bignum ** :symbol
    end
  end
end
