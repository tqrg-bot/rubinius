require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes.rb'

describe "String#count" do
  it "counts occurrences of chars from the intersection of the specified sets" do
    s = "hello\nworld\x00\x00"

    s.count(s).should == s.size
    s.count("lo").should == 5
    s.count("eo").should == 3
    s.count("l").should == 3
    s.count("\n").should == 1
    s.count("\x00").should == 2
    
    s.count("").should == 0
    "".count("").should == 0

    s.count("l", "lo").should == s.count("l")
    s.count("l", "lo", "o").should == s.count("")
    s.count("helo", "hel", "h").should == s.count("h")
    s.count("helo", "", "x").should == 0
  end

  it "raises ArgumentError when given no arguments" do
    should_raise(ArgumentError) { "hell yeah".count }
  end

  it "negates sets starting with ^" do
    s = "^hello\nworld\x00\x00"
    
    s.count("^").should == 1 # no negation, counts ^

    s.count("^leh").should == 9
    s.count("^o").should == 12

    s.count("helo", "^el").should == s.count("ho")
    s.count("aeiou", "^e").should == s.count("aiou")
    
    "^_^".count("^^").should == 1
    "oa^_^o".count("a^").should == 3
  end

  it "counts all chars in a sequence" do
    s = "hel-[()]-lo012^"
    
    s.count("\x00-\xFF").should == s.size
    s.count("ej-m").should == 3
    s.count("e-h").should == 2

    # no sequences
    s.count("-").should == 2
    s.count("e-").should == s.count("e") + s.count("-")
    s.count("-h").should == s.count("h") + s.count("-")

    s.count("---").should == s.count("-")
    
    # see an ASCII table for reference
    s.count("--2").should == s.count("-./012")
    s.count("(--").should == s.count("()*+,-")
    s.count("A-a").should == s.count("A-Z[\\]^_`a")
    
    # empty sequences (end before start)
    s.count("h-e").should == 0
    s.count("^h-e").should == s.size

    # negated sequences
    s.count("^e-h").should == s.size - s.count("e-h")
    s.count("^^-^").should == s.size - s.count("^")
    s.count("^---").should == s.size - s.count("-")

    "abcdefgh".count("a-ce-fh").should == 6
    "abcdefgh".count("he-fa-c").should == 6
    "abcdefgh".count("e-fha-c").should == 6

    "abcde".count("ac-e").should == 4
    "abcde".count("^ac-e").should == 1
  end

  it "tries to convert each set arg to a string using to_str" do
    other_string = Object.new
    def other_string.to_str() "lo" end

    other_string2 = Object.new
    def other_string2.to_str() "o" end

    s = "hello world"
    s.count(other_string, other_string2).should == s.count("o")
    
    obj = Object.new
    obj.should_receive(:respond_to?, :with => [:to_str], :count => :any, :returning => true)
    obj.should_receive(:method_missing, :with => [:to_str], :returning => "k")
    s = "hacker kimono"
    s.count(obj).should == s.count("k")
  end
 
  it "raises a TypeError when a set arg can't be converted to a string" do
    should_raise(TypeError) { "hello world".count(?o) }
    should_raise(TypeError) { "hello world".count(:o) }
    should_raise(TypeError) { "hello world".count(Object.new) }
  end
end
