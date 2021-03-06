require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/methods'

describe "Time.at" do
  it "converts to time object" do
    Time.at( 1168475924 ).inspect.should == localtime(1168475924)
  end
  
  it "creates a new time object with the value given by time" do
    t = Time.now
    Time.at(t).inspect.should == t.inspect
  end
  
  it "creates a dup time object with the value given by time" do
    t1 = Time.new
    t2 = Time.at(t1)
    t1.object_id.should_not == t2.object_id
  end
end
