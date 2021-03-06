require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Bignum#&" do
  before(:each) do
    @bignum = BignumHelper.sbm(5)
  end
  
  it "returns self bitwise AND other" do
    @bignum = BignumHelper.sbm(5)
    (@bignum & 3).should == 1
    (@bignum & 52).should == 4
    (@bignum & BignumHelper.sbm(9921)).should == 1073741825

    (18446744073709551616 & 1).should == 0
    (18446744073709551616 & -1).should == 18446744073709551616
    (36893488147419103232 & -1).should == 36893488147419103232
    (18446744073709551616 & 18446744073709551616).should == 18446744073709551616
  end

  it "tries to convert it's argument to an Integer using to_int" do
    (@bignum & 3.4).should == 1
    
    (obj = Object.new).should_receive(:to_int, :returning => 3)
    (@bignum & obj).should == 1
  end
  
  it "raises a TypeError when the given argument can't be converted to Integer" do
    obj = Object.new
    should_raise(TypeError) { @bignum & obj }
    
    obj.should_receive(:to_int, :returning => "asdf")
    should_raise(TypeError) { @bignum & obj }
  end
end
