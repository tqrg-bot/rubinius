require File.dirname(__FILE__) + '/../../spec_helper'

describe "Float#hash" do
  it "is provided" do
    0.0.respond_to?(:hash).should == true
  end
end
