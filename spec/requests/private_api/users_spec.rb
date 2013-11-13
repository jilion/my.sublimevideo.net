require 'spec_helper'

describe 'Private API Users requests' do
  let!(:user1) { create(:user, updated_at: Time.utc(2013, 4, 25)) }
  let!(:user2) { create(:user, state: 'archived') }

  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'show' do
    it_behaves_like 'valid caching headers' do
      let(:url) { "private_api/users/#{user1.id}.json" }
      let(:record) { user1 }
    end

    context 'non existing user' do
      it 'returns 404' do
        get 'private_api/users/42.json', {}, @env
        expect(response.status).to eq 404
        expect(MultiJson.load(response.body)).to eq({ 'error' => 'Resource could not be found.' })
      end
    end

    context 'existing user' do
      it 'finds user per id' do
        get "private_api/users/#{user1.id}.json", {}, @env
        expect(MultiJson.load(response.body)['id']).to eq user1.id
        expect(response.status).to eq 200
      end
    end

    context 'archived user' do
      it 'returns 404' do
        get "private_api/users/#{user2.id}.json", {}, @env
        expect(response.status).to eq 404
        expect(MultiJson.load(response.body)).to eq({ 'error' => 'Resource could not be found.' })
      end
    end
  end

end
