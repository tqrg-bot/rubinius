require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes.rb'

describe "String#inspect" do
  # Older versions of MRI wrongly print \b as \010
  it "produces a version of self with all nonprinting charaters replaced by \\nnn notation" do
    ("\000".."A").to_a.to_s.inspect.should == "\"\\000\\001\\002\\003\\004\\005\\006\\a\\b\\t\\n\\v\\f\\r\\016\\017\\020\\021\\022\\023\\024\\025\\026\\027\\030\\031\\032\\e\\034\\035\\036\\037 !\\\"\\\#$%&'()*+,-./0123456789\""
  end
  
  it "produces different output based on $KCODE" do
    old_kcode = $KCODE

    begin
      $KCODE = "NONE"
      "äöü".inspect.should == "\"\\303\\244\\303\\266\\303\\274\""

      $KCODE = "UTF-8"
      "äöü".inspect.should == "\"äöü\""
    ensure
      $KCODE = old_kcode
    end
  end
  
  it "taints the result if self is tainted" do
    "foo".taint.inspect.tainted?.should == true
    "foo\n".taint.inspect.tainted?.should == true
  end
end
