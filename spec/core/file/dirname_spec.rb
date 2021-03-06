require File.dirname(__FILE__) + '/../../spec_helper'

describe "File.dirname" do   
  it "dirname should return all the components of filename except the last one" do
    File.dirname('/home/jason').should == '/home'
    File.dirname('/home/jason/poot.txt').should == '/home/jason'
    File.dirname('poot.txt').should == '.'
    File.dirname('/holy///schnikies//w00t.bin').should == '/holy///schnikies'
    File.dirname('').should == '.'
    File.dirname('/').should == '/'
    File.dirname('/////').should == '/'
  end 
  
  it "return a String" do
    File.dirname("foo").class.should == String
  end

  it "not modify its argument" do
    x = "/usr/bin"
    File.dirname(x)
    x.should == "/usr/bin"
  end

  it "return the return all the components of filename except the last one (unix format)" do
    File.dirname("foo").should =="."
    File.dirname("/foo").should =="/"
    File.dirname("/foo/bar").should =="/foo"
    File.dirname("/foo/bar.txt").should =="/foo"
    File.dirname("/foo/bar/baz").should =="/foo/bar"
  end

  platform :not, :mswin do
    it "return all the components of filename except the last one (edge cases)" do
      File.dirname("").should == "."
      File.dirname(".").should == "."
      File.dirname("./").should == "."
      File.dirname("./b/./").should == "./b"
      File.dirname("..").should == "."
      File.dirname("../").should == "."
      File.dirname("/").should == "/"
      File.dirname("/.").should == "/"
      File.dirname("/foo/").should == "/"    
      File.dirname("//foo//").should == "/"
      File.dirname("/foo/.").should == "/foo"
      File.dirname("/foo/./").should == "/foo"
      File.dirname("/foo/../.").should == "/foo/.."
      File.dirname("foo/../").should == "foo"
    end
  end
  
  platform :mswin do
    it "return all the components of filename except the last one (edge cases)" do
      File.dirname("//foo").should == "/"
    end
  end

  it "raise an exception if the arguments are wrong type or are the incorect number of arguments " do
    should_raise(TypeError){ File.dirname(nil) }
    should_raise(TypeError){ File.dirname(0) }
    should_raise(TypeError){ File.dirname(true) }
    should_raise(TypeError){ File.dirname(false) }
  end

  # Windows specific tests
  platform :mswin do
    it "return the return all the components of filename except the last one (Windows format)" do 
      File.dirname("C:\\foo\\bar\\baz.txt").should =="C:\\foo\\bar"
      File.dirname("C:\\foo\\bar").should =="C:\\foo"
      File.dirname("C:\\foo\\bar\\").should == "C:\\foo"
      File.dirname("C:\\foo").should == "C:\\"
      File.dirname("C:\\").should =="C:\\"
    end

    it "return the return all the components of filename except the last one (windows unc)" do
      File.dirname("\\\\foo\\bar\\baz.txt").should == "\\\\foo\\bar"
      File.dirname("\\\\foo\\bar\\baz").should == "\\\\foo\\bar"
      File.dirname("\\\\foo").should =="\\\\foo"
      File.dirname("\\\\foo\\bar").should =="\\\\foo\\bar"
    end
         
    it "return the return all the components of filename except the last one (forward_slash)" do 
      File.dirname("C:/").should == "C:/"
      File.dirname("C:/foo").should == "C:/"
      File.dirname("C:/foo/bar").should == "C:/foo"
      File.dirname("C:/foo/bar/").should == "C:/foo"
      File.dirname("C:/foo/bar//").should == "C:/foo"
    end
  end 
end
