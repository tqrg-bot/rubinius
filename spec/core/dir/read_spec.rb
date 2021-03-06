require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/common'
require File.dirname(__FILE__) + '/shared/closed'

describe "Dir#read" do
  it "returns the file name in the current seek position" do
    # an FS does not necessarily impose order
    ls = `ls -a #{mock_dir}`.split
    dir = Dir.open mock_dir
    ls.should_include(dir.read)
    dir.close
  end
end

describe "Dir#read" do
  it_behaves_like :dir_closed, :read
end
