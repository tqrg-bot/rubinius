shared :hash_replace do |cmd|
  describe "Hash##{cmd}" do
    it "replaces the contents of self with other" do
      h = { :a => 1, :b => 2 }
      h.send(cmd, :c => -1, :d => -2).equal?(h).should == true
      h.should == { :c => -1, :d => -2 }
    end

    it "calls to_hash on its argument" do
      obj = Object.new
      obj.should_receive(:to_hash, :returning => {1 => 2, 3 => 4})

      h = {}
      h.send(cmd, obj)
      h.should == {1 => 2, 3 => 4}

      obj = Object.new
      obj.should_receive(:respond_to?, :with => [:to_hash], :count => :any, :returning => true)
      obj.should_receive(:method_missing, :with => [:to_hash], :returning => {})

      h.send(cmd, obj)
      h.should == {}
    end

    it "calls to_hash on hash subclasses" do
      h = {}
      h.send(cmd, ToHashHash[1 => 2])
      h.should == {1 => 2}
    end

    it "does not transfer default values" do
      hash_a = {}
      hash_b = Hash.new(5)
      hash_a.send(cmd, hash_b)
      hash_a.default.should == 5

      hash_a = {}
      hash_b = Hash.new { |h, k| k * 2 }
      hash_a.send(cmd, hash_b)
      hash_a.default(5).should == 10

      hash_a = Hash.new { |h, k| k * 5 }
      hash_b = Hash.new(lambda { raise "Should not invoke lambda" })
      hash_a.send(cmd, hash_b)
      hash_a.default.should == hash_b.default
    end

    compliant :mri do
      it "raises TypeError if called on a frozen instance" do
        @hash.send(cmd, @hash) # ok, nothing changed
        should_raise(TypeError) { @hash.send(cmd, @empty) }
      end
    end
  end
end
