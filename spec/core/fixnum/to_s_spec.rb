require File.dirname(__FILE__) + '/../../spec_helper'

describe "Fixnum#to_s when given a base" do
  it "returns self converted to a String in the given base" do
    12345.to_s(2).should == "11000000111001"
    12345.to_s(8).should == "30071"
    12345.to_s(10).should == "12345"
    12345.to_s(16).should == "3039"
    12345.to_s(36).should == "9ix"
  end
  
  it "raises an ArgumentError if the base is less than 2 or higher than 36" do
    should_raise(ArgumentError) { 123.to_s(-1) }
    should_raise(ArgumentError) { 123.to_s(0) }
    should_raise(ArgumentError) { 123.to_s(1) }
    should_raise(ArgumentError) { 123.to_s(37) }
  end
end

describe "Fixnum#to_s when no base given" do
  it "returns self converted to a String using base 10" do
    255.to_s.should == '255'
    3.to_s.should == '3'
    0.to_s.should == '0'
    -9002.to_s.should == '-9002'
  end
end
