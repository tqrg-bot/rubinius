require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes.rb'
require File.dirname(__FILE__) + '/shared/each.rb'

describe "String#each" do
  it_behaves_like(:string_each, :each)
end
