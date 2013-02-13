require 'fast_spec_helper'
require 'support/sidekiq_custom_matchers'

require 'wrappers/edge_cast_wrapper'
require 'wrappers/voxcast_wrapper'
require 'wrappers/cdn'

describe CDN do

  describe "purge" do

    context "with two wrappers" do

      it "calls purge method on all wrappers" do
        EdgeCastWrapper.should delay(:purge).with('/file.path')
        VoxcastWrapper.should delay(:purge).with('/file.path')

        CDN.purge('/file.path')
      end

    end
  end

end
