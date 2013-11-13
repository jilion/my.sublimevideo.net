require 'fast_spec_helper'

require 'models/public_launch'

describe PublicLaunch do

  it 'returns beta_transition_started_on from yaml file' do
    expect(PublicLaunch.beta_transition_started_on).to eq Time.utc(2011, 3, 29)
  end

end
