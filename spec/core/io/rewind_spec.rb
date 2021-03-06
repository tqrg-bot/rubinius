require File.dirname(__FILE__) + '/../../spec_helper'

describe "IO#rewind" do
  before :each do
    @file = File.open(File.dirname(__FILE__) + '/fixtures/readlines.txt', 'r')
    @io = IO.open @file.fileno
  end
  
  after :each do
    @file.close
  end
  
  it "positions the instance to the beginning of input" do
    @io.readline.should == "Voici la ligne une.\n"
    @io.readline.should == "Qui è la linea due.\n"
    @io.rewind
    @io.readline.should == "Voici la ligne une.\n"
  end
  
  it "sets lineno to 0" do
    @io.readline.should == "Voici la ligne une.\n"
    @io.lineno.should == 1
    @io.rewind
    @io.lineno.should == 0
  end
end
