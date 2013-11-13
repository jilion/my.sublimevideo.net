require 'fast_spec_helper'

require 'wrappers/twitter_wrapper'

describe TwitterWrapper do

  describe 'method_missing' do
    it 'delegates to Twitter if possible' do
      expect(Twitter).to receive(:favorites)

      TwitterWrapper.favorites
    end
  end

end
