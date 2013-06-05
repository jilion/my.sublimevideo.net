require 'spec_helper'

describe 'Private API Users requests' do
  let!(:user1) { create(:user, updated_at: Time.utc(2013, 4, 25)) }
  let!(:user2) { create(:user, state: 'archived') }

  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'show' do
    describe 'caching strategy' do
      it_behaves_like 'valid caching headers' do
        let(:url) { "private_api/users/#{user1.id}.json" }
        let(:expected_last_modified) { user1.updated_at }
        let(:update_record) { -> { user1.update_attribute(:email, 'joe@example.com') } }
      end
    end

    context 'non existing user' do
      it 'raises an ActiveRecord::RecordNotFound' do
        get 'private_api/users/42.json', {}, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => 'User with id 42 could not be found.' })
      end
    end

    context 'existing user' do
      it 'finds user per id' do
        get "private_api/users/#{user1.id}.json", {}, @env
        MultiJson.load(response.body)['id'].should eq user1.id
        response.status.should eq 200
      end
    end

    context 'archived user' do
      it 'raises an ActiveRecord::RecordNotFound' do
        get "private_api/users/#{user2.id}.json", {}, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => "User with id #{user2.id} could not be found." })
      end
    end
  end

end
