require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Math.asinh" do
  it "returns a float" do
    Math.asinh(1.5).class.should == Float
  end
  
  it "returns the inverse hyperbolic sin of the argument" do
    Math.asinh(1.5).should_be_close(1.19476321728711, TOLERANCE)
    Math.asinh(-2.97).should_be_close(-1.8089166921397, TOLERANCE)
    Math.asinh(0.0).should == 0.0
    Math.asinh(-0.0).should == -0.0
  end
  
  it "raises an ArgumentError if the argument cannot be coerced with Float()" do    
    should_raise(ArgumentError) { Math.asinh("test") }
  end
  
  it "raises a TypeError if the argument is nil" do
    should_raise(TypeError) { Math.asinh(nil) }
  end

  it "accepts any argument that can be coerced with Float()" do
    Math.asinh(MathSpecs::Float.new).should_be_close(0.881373587019543, TOLERANCE)
  end
end

describe "Math#asinh" do
  it "is accessible as a private instance method" do
    IncludesMath.new.send(:asinh, 19.275).should_be_close(3.65262832292466, TOLERANCE)
  end
end
