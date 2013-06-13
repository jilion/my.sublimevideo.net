require 'fast_spec_helper'

require 'models/public_launch'

describe PublicLaunch do

  it 'returns beta_transition_started_on from yaml file' do
    PublicLaunch.beta_transition_started_on.should eq Time.utc(2011, 3, 29)
  end

end
