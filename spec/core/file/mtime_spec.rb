require File.dirname(__FILE__) + '/../../spec_helper'

describe "File.mtime" do
  before :each do
    @filename = '/tmp/i_exist'
    File.open(@filename, 'w') { }
  end

  after :each do
    File.delete(@filename) if File.exist?(@filename)
  end

  it "returns the modification Time of the file" do
    File.mtime(@filename).class.should == Time
    File.mtime(@filename).should_be_close(Time.now, 1.0)
  end

  it "raises an Errno::ENOENT exception if the file is not found" do
    should_raise(Errno::ENOENT) { File.mtime('bogus') }
  end
end
