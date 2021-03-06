shared :kernel_kind_of do |cmd|
  describe "Object##{cmd}" do
    it "returns true if class is the class of obj, or if class is one of the superclasses of obj or modules included in obj (String example)" do
      s = "hello"
      s.send(cmd, String).should == true
      s.send(cmd, Object).should == true
      s.send(cmd, Class).should == false
      s.send(cmd, Kernel).should == true
    end

    it "returns true if class is the class of obj, or if class is one of the superclasses of obj or modules included in obj Array example" do
      a = []
      a.send(cmd, Array).should == true
      a.send(cmd, Enumerable).should == true
      a.send(cmd, Comparable).should == false
    end
          
    module KernelSpecs::M; end
    class KernelSpecs::X; include KernelSpecs::M; end
    class KernelSpecs::Y < KernelSpecs::X; end
    class KernelSpecs::Z < KernelSpecs::Y; end 
  
    it "returns true if class is the class of obj, or if class is one of the superclasses of obj or modules included in obj Custom class example" do
      y = KernelSpecs::Y.new
      y.send(cmd, KernelSpecs::X).should == true
      y.send(cmd, KernelSpecs::Y).should == true
      y.send(cmd, KernelSpecs::Z).should == false
      y.send(cmd, KernelSpecs::M).should == true
    end
    
    it "nil.#{cmd} cases specs"  do
      (nil.send(cmd, NilClass)).should == true
      (nil.send(cmd, Object)).should == true
      (nil.send(cmd, Module)).should == false
      (nil.send(cmd, Kernel)).should == true
    end
  end
end
