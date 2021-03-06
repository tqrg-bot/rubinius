require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Module#module_function" do
  it "creates module functions for the given methods" do
    m = Module.new do
      def test()  end
      def test2() end
      def test3() end
      
      module_function :test, :test2
    end
    
    m.respond_to?(:test).should  == true
    m.respond_to?(:test2).should == true
    m.respond_to?(:test3).should == false
  end

  it "makes the instance method versions private" do
    m = Module.new do
      def test() "hello" end
      module_function :test
    end
    
    (o = Object.new).extend(m)
    o.respond_to?(:test).should == false
    o.send(:test).should == "hello"
  end
  
  it "makes subsequently defined methods module functions if no names are given" do
    m = Module.new do
      module_function
        def test() end
        def test2() end
      public
        def test3() end
    end

    m.respond_to?(:test).should  == true
    m.respond_to?(:test2).should == true
    m.respond_to?(:test3).should == false
  end
  
  it "tries to convert the given names to strings using to_str" do
    (o = Object.new).should_receive(:to_str, :returning => "test", :count => :any)
    (o2 = Object.new).should_receive(:to_str, :returning => "test2", :count => :any)
    
    m = Module.new do
      def test() end
      def test2() end
      module_function o, o2
    end
    
    m.respond_to?(:test).should  == true
    m.respond_to?(:test2).should == true
  end

  it "raises a TypeError when the given names can't be converted to string using to_str" do
    o = Object.new
    
    should_raise(TypeError, "#{o} is not a symbol") do
      Module.new { module_function(o) }
    end

    o.should_receive(:to_str, :returning => 123)
    should_raise(TypeError, "Object#to_str should return String") do
      Module.new { module_function(o) }
    end
  end
end
