require File.dirname(__FILE__) + '/../../spec_helper'

describe "Fixnum#<<" do
  it "returns self shifted the given amount of bits to the left" do
    (7 << 2).should == 28
    (9 << 4).should == 144
  end

  it "performs a right-shift if given a negative value" do
    (7 << -2).should == (7 >> 2)
    (9 << -4).should == (9 >> 4)
  end
  
  it "coerces result on overflow and return self shifted left other bits" do
    (9 << 4.2).should == 144
    (6 << 0xff).should == 347376267711948586270712955026063723559809953996921692118372752023739388919808
  end
  
  it "tries to convert its argument to an Integer using to_int" do
    (5 << 4.3).should == 80
    
    (obj = Object.new).should_receive(:to_int, :returning => 4)
    (3 << obj).should == 48
  end
  
  it "raises a TypeError when the given argument can't be converted to Integer" do
    obj = Object.new
    should_raise(TypeError) { 3 << obj }
    
    obj.should_receive(:to_int, :returning => "asdf")
    should_raise(TypeError) { 3 << obj }
  end
end
