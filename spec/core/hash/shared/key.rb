shared :hash_key_p do |cmd|
  describe "Hash##{cmd}" do
    it "returns true if argument is a key" do
      h = { :a => 1, :b => 2, :c => 3, 4 => 0 }
      h.send(cmd, :a).should == true
      h.send(cmd, :b).should == true
      h.send(cmd, 'b').should == false
      h.send(cmd, 2).should == false
      h.send(cmd, 4).should == true
      h.send(cmd, 4.0).should == false
    end

    it "returns true if the key's matching value was nil" do
      { :xyz => nil }.send(cmd, :xyz).should == true
    end

    it "returns true if the key's matching value was false" do
      { :xyz => false }.send(cmd, :xyz).should == true
    end
  end
end
