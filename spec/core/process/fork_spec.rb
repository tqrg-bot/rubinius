require File.dirname(__FILE__) + '/../../spec_helper'

describe "Process.fork" do
  before :each do
    @file = '/tmp/i_exist'
  end
  
  after :each do
    File.delete(@file) if File.exist?(@file)
  end
  
  it "return nil for the child process" do
    child_id = Process.fork
    if child_id == nil
      File.open(@file,'w'){|f| f.write 'rubinius'}
      Process.exit!
    else
      Process.waitpid(child_id)
    end
    File.exist?(@file).should == true
  end
end
