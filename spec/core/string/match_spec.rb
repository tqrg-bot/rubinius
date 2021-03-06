require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes.rb'

describe "String#=~" do
  it "behaves the same way as index() when given a regexp" do
    ("rudder" =~ /udder/).should == "rudder".index(/udder/)
    ("boat" =~ /[^fl]oat/).should == "boat".index(/[^fl]oat/)
    ("bean" =~ /bag/).should == "bean".index(/bag/)
    ("true" =~ /false/).should == "true".index(/false/)
  end

  it "raises a TypeError if a obj is a string" do
    should_raise(TypeError) { "some string" =~ "another string" }
    should_raise(TypeError) { "a" =~ MyString.new("b") }
  end
  
  it "invokes obj.=~ with self if obj is neither a string nor regexp" do
    str = "w00t"
    obj = Object.new

    obj.should_receive(:=~, :with => [str], :returning => true)
    (str =~ obj).should == true

    obj.should_receive(:=~, :with => [str], :returning => false)
    (str =~ obj).should == false
  end
  
  it "sets $~ to MatchData when there is a match and nil when there's none" do
    'hello' =~ /./
    $~[0].should == 'h'
    
    'hello' =~ /not/
    $~.should == nil
  end
end

describe "String#match" do
  it "matches the pattern against self" do
    'hello'.match(/(.)\1/)[0].should == 'll'
  end
  
  it "tries to convert pattern to a string via to_str" do
    obj = Object.new
    def obj.to_str() "." end
    "hello".match(obj)[0].should == "h"
    
    obj = Object.new
    def obj.respond_to?(type) true end
    def obj.method_missing(*args) "." end
    "hello".match(obj)[0].should == "h"    
  end
  
  it "raises a TypeError if pattern is not a regexp or a string" do
    should_raise(TypeError) { 'hello'.match(10) }
    should_raise(TypeError) { 'hello'.match(:ell) }
  end

  it "converts string patterns to regexps without escaping" do
    'hello'.match('(.)\1')[0].should == 'll'
  end
  
  it "returns nil if there's no match" do
    'hello'.match('xx').should == nil
  end

  it "matches \\G at the start of the string" do
    'hello'.match(/\Gh/)[0].should == 'h'
    'hello'.match(/\Go/).should == nil
  end

  it "sets $~ to MatchData of match or nil when there is none" do
    'hello'.match(/./)
    $~[0].should == 'h'
    Regexp.last_match[0].should == 'h'

    'hello'.match(/X/)
    $~.should == nil
    Regexp.last_match.should == nil
  end
end
