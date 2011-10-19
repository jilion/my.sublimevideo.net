require 'spec_helper'

describe TwitterApi do

  describe "method_missing" do
    it "delegates to Twitter if possible" do
      TwitterApi.should_receive(:search)

      TwitterApi.search
    end
  end

end
