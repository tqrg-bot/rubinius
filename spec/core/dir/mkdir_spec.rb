require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/common'

describe "Dir.mkdir" do
  it "creates the named directory with the given permissions" do
    clear_dirs

    begin
      File.exist?('nonexisting').should == false
      Dir.mkdir 'nonexisting'
      File.exist?('nonexisting').should == true

      Dir.mkdir 'default_perms'
      a = File.stat('default_perms').mode
      Dir.mkdir 'reduced', (a - 1)
      File.stat('reduced').mode.should_not == a

      Dir.mkdir('always_returns_0').should == 0

      system "chmod 0777 nonexisting default_perms reduced always_returns_0"
    ensure
      clear_dirs
    end
  end

  it "raises without adequate permissions in the parent dir" do
    Dir.mkdir 'noperms', 0000

    should_raise(SystemCallError) { Dir.mkdir 'noperms/subdir' }

    system 'chmod 0777 noperms'
    Dir.rmdir 'noperms'
  end

  it "raises a SystemCallError if any of the directories in the path before the last does not exist" do
    should_raise(SystemCallError) { Dir.mkdir "#{nonexistent}/subdir" }
  end
end
