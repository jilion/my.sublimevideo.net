require 'spec_helper'

describe 'Private API Referrers requests' do
  let!(:referrer1) { create(:referrer) }
  let!(:referrer2) { create(:referrer) }

  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'index' do
    it 'supports :per scope' do
      get 'private_api/referrers.json', { per: 2 }, @env
      MultiJson.load(response.body).should have(2).referrers
    end

    it 'supports :with_tokens scope' do
      get 'private_api/referrers.json', { with_tokens: [referrer1.token, referrer2.token] }, @env
      body = MultiJson.load(response.body)
      body.should have(2).referrers
      body[0]['token'].should eq referrer1.token
      body[1]['token'].should eq referrer2.token
    end
  end

end
