require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/subtend_helper'

extension :rubinius do
  compile_extension('subtend_exception')
  require File.dirname(__FILE__) + '/ext/subtend_exception'

  context "SubtendRaiser" do
    setup do
      @s = SubtendRaiser.new
    end
  
    specify "rb_raise should raise an exception" do
      should_raise(TypeError) do
        @s.raise!
      end
    end
  
    specify "rb_raise terminates the function early" do
      h = {}
      should_raise(TypeError) do
        @s.raise_early(h)
      end

      h[:screwed].should == false
    end
  end
end
