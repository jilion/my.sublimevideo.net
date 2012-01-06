require 'spec_helper'

describe TwitterApi do

  describe "method_missing" do
    it "delegates to Twitter if possible" do
      TwitterApi.should_receive(:favorites)

      TwitterApi.favorites
    end
  end

end
