require 'fast_spec_helper'
require 'support/matchers/sidekiq_matchers'

require 'wrappers/cdn'

describe CDN do

  describe 'purge' do
    context 'with two wrappers' do
      it 'calls purge method on all wrappers' do
        EdgeCastWrapper.should delay(:purge).with('/file.path')
        VoxcastWrapper.should delay(:purge).with('/file.path')

        described_class.purge('/file.path')
      end
    end
  end

end
