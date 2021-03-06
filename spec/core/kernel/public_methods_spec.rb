require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Kernel#public_methods" do
  it "returns a list of the names of publicly accessible methods in the object" do
    KernelSpecs::Methods.public_methods(false).sort.should == 
      ["allocate", "hachi", "ichi", "juu", "juu_ni", "new", "roku", "san", "shi", "superclass"]
    KernelSpecs::Methods.new.public_methods(false).sort.should == ["juu_san", "ni"]
  end
  
  it "returns a list of the names of publicly accessible methods in the object and its ancestors and mixed-in modules" do
    (KernelSpecs::Methods.public_methods(false) & KernelSpecs::Methods.public_methods).sort.should == 
      ["allocate", "hachi", "ichi", "juu", "juu_ni", "new", "roku", "san", "shi", "superclass"]
    m = KernelSpecs::Methods.new.public_methods
    m.should_include('ni')
    m.should_include('juu_san')
  end
end
