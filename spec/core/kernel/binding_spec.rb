require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Kernel#binding" do
  before(:each) do
    @b1 = KernelSpecs::Binding.new(99).get_binding
  end

  it "should return a Binding object" do
    @b1.kind_of?(Binding).should == true
  end

  it "should encapsulate the execution context properly" do
    eval("@secret", @b1).should == 100
    eval("a", @b1).should == true
    eval("b", @b1).should == true
    eval("@@super_secret", @b1).should == "password"

    eval("square(2)", @b1).should == 4
    eval("self.square(2)", @b1).should == 4

    eval("a = false", @b1)
    eval("a", @b1).should == false
  end

  it "should raise NameError on undefined variable" do
    should_raise(NameError) { eval("a_fake_variable", @b1) }
  end
end
