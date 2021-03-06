require File.dirname(__FILE__) + '/../../spec_helper'

describe "Float#CONSTANTS" do 
  specify  "the DIG value is  15" do
    Float::DIG.should_be_close(15,TOLERANCE)
  end
  
  specify "the EPSILON value is " do
    Float::EPSILON.should_be_close(2.22044604925031e-16,TOLERANCE)
  end
  
  specify "the MANT_DIG is 53" do
    Float::MANT_DIG.should_be_close(53,TOLERANCE)
  end
  
  specify "the MAX_10_EXP is 308" do
    Float::MAX_10_EXP.should == 308
  end
  
  specify "the MIN_10_EXP is -308" do    
    Float::MIN_10_EXP.should == -307
  end  
  
  specify "the MAX_EXP is 1024" do    
    Float::MAX_EXP.should_be_close(1024,TOLERANCE)
  end
  
  specify "the MIN_EXP is -1021" do
    Float::MIN_EXP.should_be_close(-1021,TOLERANCE)
  end   
  
  specify "the MIN_EXP is 1.79769313486232e+308" do
    Float::MIN_EXP.should_be_close(-1021,TOLERANCE)
  end 
  
  specify "the MAX is 1.79769313486232e+308" do
    Float::MAX.to_s.should == "1.79769313486232e+308".to_s    
  end 
  
  specify "the MIN is 2.2250738585072e-308" do    
    Float::MIN.should_be_close(2.2250738585072e-308,TOLERANCE)    
  end 
  
  specify "the RADIX is 2" do
    Float::RADIX.should_be_close(2,TOLERANCE)
  end
end
