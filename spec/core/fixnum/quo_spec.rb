require File.dirname(__FILE__) + '/../../spec_helper'

describe "Fixnum#quo" do
  it "returns the result of self divided by the given Integer as a Float" do
    2.quo(2.5).should == 0.8
    5.quo(2).should == 2.5
    45.quo(0xffffffff).should_be_close(1.04773789668636e-08, TOLERANCE)
  end

  it "does not raise a ZeroDivisionError when the given Integer is 0" do
    0.quo(0).to_s.should == "NaN"
    10.quo(0).to_s.should == "Infinity"
    -10.quo(0).to_s.should == "-Infinity"
  end

  it "does not raise a FloatDomainError when the given Integer is 0 and a Float" do
    0.quo(0.0).to_s.should == "NaN"
    10.quo(0.0).to_s.should == "Infinity"
    -10.quo(0.0).to_s.should == "-Infinity"
  end

  it "raises a TypeError when given a non-Integer" do
    should_raise(TypeError) do
      (obj = Object.new).should_not_receive(:to_int)
      13.quo(obj)
    end
    
    should_raise(TypeError) do
      13.quo("10")
    end

    should_raise(TypeError) do
      13.quo(:symbol)
    end
  end
end
