require 'spec_helper'

describe 'Private API Users requests' do
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user, state: 'archived') }
  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'show' do
    context 'non existing user' do
      it 'raise an ActiveRecord::RecordNotFound' do
        expect { get 'private_api/users/42.json', {}, @env }.to raise_error(ActiveRecord::RecordNotFound)
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
      it 'finds user per id' do
        expect { get "private_api/users/#{user2.id}.json", {}, @env }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

end
