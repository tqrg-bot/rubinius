require File.dirname(__FILE__) + '/../../spec_helper'

describe "Range#to_a" do
  it "converts self to an array" do
    (-5..5).to_a.should == [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]
    ('A'..'D').to_a.should == ['A','B','C','D']
    ('A'...'D').to_a.should == ['A','B','C']    
    (0xfffd...0xffff).to_a.should == [0xfffd,0xfffe]
    should_raise(TypeError) do
      (0.5..2.4).to_a
    end
  end
end