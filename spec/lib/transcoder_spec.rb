require 'spec_helper'

describe Transcoder do
  
  describe ".put(item, id, hash)" do
    it "should raise an exception if the id given is nil" do
      lambda { Transcoder.put(:foo, nil, {}) }.should raise_error(RuntimeError, "id can't be nil!")
    end
  end
  
  describe ".delete(item, id)" do
    it "should raise an exception if the id given is nil" do
      lambda { Transcoder.delete(:foo, nil) }.should raise_error(RuntimeError, "id can't be nil!")
    end
  end
  
end