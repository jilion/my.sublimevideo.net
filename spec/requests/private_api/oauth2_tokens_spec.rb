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
    let(:url) { "private_api/oauth2_tokens/#{token1.token}.json" }

    it_behaves_like 'valid caching headers' do
      let(:record) { token1 }
    end

    context 'non existing Oauth2 token' do
      it 'returns 404' do
        get 'private_api/oauth2_tokens/42.json', {}, @env
        expect(response.status).to eq 404
        expect(MultiJson.load(response.body)).to eq({ 'error' => 'Resource could not be found.' })
      end
    end

    context 'invalidated token' do
      it 'returns 404' do
        get "private_api/oauth2_tokens/#{token2.token}.json", {}, @env
        expect(response.status).to eq 404
        expect(MultiJson.load(response.body)).to eq({ 'error' => 'Resource could not be found.' })
      end
    end

    context 'unauthorized token' do
      it 'returns 404' do
        get "private_api/oauth2_tokens/#{token3.token}.json", {}, @env
        expect(response.status).to eq 404
        expect(MultiJson.load(response.body)).to eq({ 'error' => 'Resource could not be found.' })
      end
    end

    context 'existing Oauth2 token' do
      it 'finds Oauth2 token per token' do
        get "private_api/oauth2_tokens/#{token1.token}.json", {}, @env
        expect(MultiJson.load(response.body)['access_token']).to eq token1.token
        expect(response.status).to eq 200
      end
    end

  end

end
