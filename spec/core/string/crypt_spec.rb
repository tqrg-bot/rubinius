require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes.rb'

describe "String#crypt" do
  # Note: MRI's documentation just says that the C stdlib function crypt() is
  # called.
  #
  # I'm not sure if crypt() is guaranteed to produce the same result across
  # different platforms. It seems that there is one standard UNIX implementation
  # of crypt(), but that alternative implementations are possible. See
  # http://www.unix.org.ua/orelly/networking/puis/ch08_06.htm
  it "returns a cryptographic hash of self by applying the UNIX crypt algorithm with the specified salt" do
    "".crypt("aa").should == "aaQSqAReePlq6"
    "nutmeg".crypt("Mi").should == "MiqkFWCm1fNJI"
    "ellen1".crypt("ri").should == "ri79kNd7V6.Sk"
    "Sharon".crypt("./").should == "./UY9Q7TvYJDg"
    "norahs".crypt("am").should == "amfIADT2iqjA."
    "norahs".crypt("7a").should == "7azfT5tIdyh0I"
    
    # Only uses first 8 chars of string
    "01234567".crypt("aa").should == "aa4c4gpuvCkSE"
    "012345678".crypt("aa").should == "aa4c4gpuvCkSE"
    "0123456789".crypt("aa").should == "aa4c4gpuvCkSE"
    
    # Only uses first 2 chars of salt
    "hello world".crypt("aa").should == "aayPz4hyPS1wI"
    "hello world".crypt("aab").should == "aayPz4hyPS1wI"
    "hello world".crypt("aabc").should == "aayPz4hyPS1wI"
    
    # Maps null bytes in salt to ..
    platform :not, :darwin do
      "hello".crypt("\x00\x00").should == ""
    end
    
    platform :darwin do
      "hello".crypt("\x00\x00").should == "..dR0/E99ehpU"
    end
  end
  
  it "raises an ArgumentError when the salt is shorter than two characters" do
    should_raise(ArgumentError) { "hello".crypt("") }
    should_raise(ArgumentError) { "hello".crypt("f") }
  end

  it "converts the salt arg to a string via to_str" do
    obj = Object.new
    def obj.to_str() "aa" end
    
    "".crypt(obj).should == "aaQSqAReePlq6"

    obj = Object.new
    obj.should_receive(:respond_to?, :with => [:to_str], :count => :any, :returning => true)
    obj.should_receive(:method_missing, :with => [:to_str], :returning => "aa")
    "".crypt(obj).should == "aaQSqAReePlq6"
  end

  it "raises a type error when the salt arg can't be converted to a string" do
    should_raise(TypeError) { "".crypt(5) }
    should_raise(TypeError) { "".crypt(Object.new) }
  end
  
  it "taints the result if either salt or self is tainted" do
    tainted_salt = "aa"
    tainted_str = "hello"
    
    tainted_salt.taint
    tainted_str.taint
    
    "hello".crypt("aa").tainted?.should == false
    tainted_str.crypt("aa").tainted?.should == true
    "hello".crypt(tainted_salt).tainted?.should == true
    tainted_str.crypt(tainted_salt).tainted?.should == true
  end
  
  it "doesn't return subclass instances" do
    MyString.new("hello").crypt("aa").class.should == String
    "hello".crypt(MyString.new("aa")).class.should == String
    MyString.new("hello").crypt(MyString.new("aa")).class.should == String
  end
end
