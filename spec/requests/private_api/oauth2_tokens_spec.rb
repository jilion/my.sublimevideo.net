require 'spec_helper'

describe 'Private API Oauth2 tokens requests' do
  let!(:token1) { create(:oauth2_token) }
  let!(:token2) { create(:oauth2_token, invalidated_at: Time.now) }
  let!(:token3) { create(:oauth2_token).tap { |t| t.update_column(:authorized_at, nil) } }

  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'show' do
    describe 'caching strategy' do
      it_behaves_like 'valid caching headers' do
        let(:url) { "private_api/oauth2_tokens/#{token1.token}.json" }
        let(:expected_last_modified) { token1.updated_at }
        let(:update_record) { -> { token1.update_attribute(:expires_at, 3.days.from_now) } }
      end
    end

    context 'non existing Oauth2 token' do
      it 'raises an ActiveRecord::RecordNotFound' do
        get 'private_api/oauth2_tokens/42.json', {}, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => 'OAuth token 42 could not be found.' })
      end
    end

    context 'invalidated token' do
      it 'raises an ActiveRecord::RecordNotFound' do
        get "private_api/oauth2_tokens/#{token2.token}.json", {}, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => "OAuth token #{token2.token} could not be found." })
      end
    end

    context 'unauthorized token' do
      it 'raises an ActiveRecord::RecordNotFound' do
        get "private_api/oauth2_tokens/#{token3.token}.json", {}, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => "OAuth token #{token3.token} could not be found." })
      end
    end

    context 'existing Oauth2 token' do
      it 'finds Oauth2 token per token' do
        get "private_api/oauth2_tokens/#{token1.token}.json", {}, @env
        MultiJson.load(response.body)['access_token'].should eq token1.token
        response.status.should eq 200
      end
    end

  end

end
