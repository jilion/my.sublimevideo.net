require 'fast_spec_helper'
require 'configurator'
require 'twitter'
require 'rescue_me'

require 'services/notifier'
require 'wrappers/twitter_wrapper'

describe TwitterWrapper do

  describe "method_missing" do
    it "delegates to Twitter if possible" do
      Twitter.should_receive(:favorites)

      TwitterWrapper.favorites
    end
  end

end
