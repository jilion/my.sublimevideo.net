require 'spec_helper'

describe 'Private API Sites requests' do
  let!(:site1) { create(:site, hostname: 'google.com', updated_at: Time.utc(2013, 4, 25)).tap { |s| s.tag_list << 'adult'; s.save! } }
  let!(:site2) { create(:site, created_at: 2.days.ago, first_billable_plays_at: Time.now.utc, updated_at: Time.utc(2013, 4, 26)) }
  let!(:site3) { create(:site, created_at: 2.days.ago, state: 'archived') }

  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'index' do
    describe 'caching strategy' do
      it_behaves_like 'valid caching headers', cache_validation: false do
        let(:url) { "private_api/sites.json" }
        let(:update_record) { -> { site1.update_attribute(:hostname, 'example.com') } }
      end
    end

    it 'supports :per scope' do
      get 'private_api/sites.json', { per: 2 }, @env
      MultiJson.load(response.body).should have(2).sites
    end

    it 'supports :not_archived scope' do
      get 'private_api/sites.json', { not_archived: true }, @env
      body = MultiJson.load(response.body)
      body.should have(2).sites
      body[0]['token'].should eq site1.token
      body[1]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :created_on scope' do
      get 'private_api/sites.json', { created_on: 2.days.ago }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :not_tagged_with scope' do
      get 'private_api/sites.json', { not_tagged_with: 'adult' }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :select scope' do
      get 'private_api/sites.json', { select: %w[token hostname] }, @env
      video_tag = MultiJson.load(response.body).first
      video_tag.should have_key('token')
      video_tag.should have_key('hostname')
      video_tag.should_not have_key('dev_hostnames')
      response.status.should eq 200
    end

    it 'supports :without_hostnames scope' do
      get 'private_api/sites.json', { without_hostnames: %w[google.com facebook.com] }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :first_billable_plays_on_week scope' do
      get 'private_api/sites.json', { first_billable_plays_on_week: Time.now.utc }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :user_id scope' do
      get "private_api/sites.json", { user_id: site1.user_id }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site1.token
      response.status.should eq 200
    end
  end

  describe 'show' do
    describe 'caching strategy' do
      it_behaves_like 'valid caching headers' do
        let(:url) { "private_api/sites/#{site1.token}.json" }
        let(:expected_last_modified) { site1.updated_at }
        let(:update_record) { -> { site1.update_attribute(:hostname, 'example.com') } }
      end
    end

    context 'non existing site' do
      it 'returns 404' do
        get 'private_api/sites/42.json', {}, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => 'Resource could not be found.' })
      end
    end

    context 'existing site' do
      it 'finds site per token' do
        get "private_api/sites/#{site1.token}.json", {}, @env
        MultiJson.load(response.body)['token'].should eq site1.token
        response.status.should eq 200
      end
    end

    context 'site belongs to given user' do
      it 'supports :user_id scope' do
        get "private_api/sites/#{site1.token}.json", { user_id: site1.user_id }, @env
        body = MultiJson.load(response.body)
        body['token'].should eq site1.token
        response.status.should eq 200
      end
    end

    context 'site do not belong to given user' do
      it 'returns 404' do
        get "private_api/sites/#{site1.token}.json", { user_id: site2.user_id }, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => 'Resource could not be found.' })
      end
    end
  end

  describe 'add_tag' do
    it 'adds tag to site' do
      put "private_api/sites/#{site2.token}/add_tag.json", { tag: 'adult' }, @env

      site2.tag_list.should include('adult')
      response.status.should eq 204
    end

    describe 'requires the :tag param' do
      it 'returns a 400 if :tag is missing' do
        put "private_api/sites/#{site1.token}/add_tag.json", {}, @env

        MultiJson.load(response.body).should eq({ 'error' => 'Missing :tag parameters.' })
        response.status.should eq 400
      end

      it 'returns a 400 if :tag is nil' do
        put "private_api/sites/#{site1.token}/add_tag.json", { tag: nil }, @env

        MultiJson.load(response.body).should eq({ 'error' => 'Missing :tag parameters.' })
        response.status.should eq 400
      end
    end
  end
end
