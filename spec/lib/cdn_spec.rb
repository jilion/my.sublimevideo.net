require 'fast_spec_helper'
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('lib/cdn')

describe CDN do

  class WrapperOne; end
  class WrapperTwo; end

  describe "purge" do

    context "with two wrappers" do
      before { CDN.wrappers = [WrapperOne, WrapperTwo] }

      it "calls purge method on all wrappers" do
        WrapperOne.should delay(:purge).with('/file.path')
        WrapperTwo.should delay(:purge).with('/file.path')

        CDN.purge('/file.path')
      end

    end
  end

end
