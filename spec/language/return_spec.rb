require File.dirname(__FILE__) + '/../spec_helper'

describe "Assignment via return" do
  it "should assign objects to block variables" do
    def r; return nil; end;      a = r(); a.should == nil
    def r; return 1; end;        a = r(); a.should == 1
    def r; return []; end;       a = r(); a.should == []
    def r; return [1]; end;      a = r(); a.should == [1]
    def r; return [nil]; end;    a = r(); a.should == [nil]
    def r; return [[]]; end;     a = r(); a.should == [[]]
    def r; return [*[]]; end;    a = r(); a.should == []
    def r; return [*[1]]; end;   a = r(); a.should == [1]
    def r; return [*[1,2]]; end; a = r(); a.should == [1,2]
  end
  
  it "should assign splatted objects to block variables" do
    def r; return *nil; end;     a = r(); a.should == nil
    def r; return *1; end;       a = r(); a.should == 1
    def r; return *[]; end;      a = r(); a.should == nil
    def r; return *[1]; end;     a = r(); a.should == 1
    def r; return *[nil]; end;   a = r(); a.should == nil
    def r; return *[[]]; end;    a = r(); a.should == []
    def r; return *[*[1]]; end;  a = r(); a.should == 1
    def r; return *[*[1,2]]; end; a = r(); a.should == [1,2]
  end

  it "should assign objects to block variables that include the splat operator inside the block" do
    def r; return; end;          a = *r(); a.should == nil
    def r; return nil; end;      a = *r(); a.should == nil
    def r; return 1; end;        a = *r(); a.should == 1
    def r; return []; end;       a = *r(); a.should == nil
    def r; return [1]; end;      a = *r(); a.should == 1
    def r; return [nil]; end;    a = *r(); a.should == nil
    def r; return [[]]; end;     a = *r(); a.should == []
    def r; return [1,2]; end;    a = *r(); a.should == [1,2]
    def r; return [*[]]; end;    a = *r(); a.should == nil
    def r; return [*[1]]; end;   a = *r(); a.should == 1
    def r; return [*[1,2]]; end; a = *r(); a.should == [1,2]    
  end
  
  it "should assign objects to splatted block variables that include the splat operator inside the block" do
    def r; return *nil; end;      *a = r(); a.should == [nil]
    def r; return *1; end;        *a = r(); a.should == [1]
    def r; return *[]; end;       *a = r(); a.should == [nil]
    def r; return *[1]; end;      *a = r(); a.should == [1]
    def r; return *[nil]; end;    *a = r(); a.should == [nil]
    def r; return *[[]]; end;     *a = r(); a.should == [[]]
    def r; return *[*[]]; end;    *a = r(); a.should == [nil]
    def r; return *[*[1]]; end;   *a = r(); a.should == [1]
    def r; return *[*[1,2]]; end; *a = r(); a.should == [[1,2]]    
  end
  
  it "should assign objects to splatted block variables that include the splat operator inside the block" do
    def r; return *nil; end;      *a = *r(); a.should == [nil]
    def r; return *1; end;        *a = *r(); a.should == [1]
    def r; return *[]; end;       *a = *r(); a.should == [nil]
    def r; return *[1]; end;      *a = *r(); a.should == [1]
    def r; return *[nil]; end;    *a = *r(); a.should == [nil]
    def r; return *[[]]; end;     *a = *r(); a.should == []
    def r; return *[*[]]; end;    *a = *r(); a.should == [nil]
    def r; return *[*[1]]; end;   *a = *r(); a.should == [1]
    def r; return *[*[1,2]]; end; *a = *r(); a.should == [1,2]    
  end
  
  it "should assign objects to multiple block variables" do
    def r; return; end;          a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return nil; end;      a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return 1; end;        a,b,*c = r(); [a,b,c].should == [1,nil,[]]
    def r; return []; end;       a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return [1]; end;      a,b,*c = r(); [a,b,c].should == [1,nil,[]]
    def r; return [nil]; end;    a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return [[]]; end;     a,b,*c = r(); [a,b,c].should == [[],nil,[]]
    def r; return [*[]]; end;    a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return [*[1]]; end;   a,b,*c = r(); [a,b,c].should == [1,nil,[]]
    def r; return [*[1,2]]; end; a,b,*c = r(); [a,b,c].should == [1,2,[]]
  end
  
  it "should assign splatted objects to multiple block variables" do
    def r; return *nil; end;      a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return *1; end;        a,b,*c = r(); [a,b,c].should == [1,nil,[]]
    def r; return *[]; end;       a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return *[1]; end;      a,b,*c = r(); [a,b,c].should == [1,nil,[]]
    def r; return *[nil]; end;    a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return *[[]]; end;     a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return *[*[]]; end;    a,b,*c = r(); [a,b,c].should == [nil,nil,[]]
    def r; return *[*[1]]; end;   a,b,*c = r(); [a,b,c].should == [1,nil,[]]
    def r; return *[*[1,2]]; end; a,b,*c = r(); [a,b,c].should == [1,2,[]]    
  end
end

describe "Return from within a begin" do
  it "should execute ensure before returning from function" do
    def f(a)
      begin
        return a
      ensure
        a << 1
      end
    end
    f([]).should == [1]
  end

  it "should execute return in ensure before returning from function" do
    def f(a)
      begin
        return a
      ensure
        return [0]
        a << 1
      end
    end
    f([]).should == [0]
  end

  it "should execute ensures in stack order before returning from function" do
    def f(a)
      begin
        begin
          return a
        ensure
          a << 2
        end
      ensure
        a << 1
      end
    end
    f([]).should == [2,1]
  end

  it "should execute return at base of ensure stack" do
    def f(a)
      begin
        begin
          return a
        ensure
          a << 2
          return 2
        end        
      ensure
        a << 1
        return 1
      end
    end
    f([]).should == 1
  end
end

describe "The return statement" do
  it "should raise an exception if used to exit a thread" do
    should_raise(ThreadError) do
      Thread.new { return }.join
    end
  end    
end

