require 'spec_helper'

describe 'Private API Sites requests' do
  let!(:site1) { create(:site, hostname: 'google.com').tap { |s| s.tag_list << 'adult'; s.save! } }
  let!(:site2) { create(:site, hostname: 'facebook.com', first_billable_plays_at: Time.now.utc) }
  let!(:site3) { create(:site, created_at: 2.days.ago, state: 'archived') }
  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'index' do
    it 'supports :per scope' do
      get 'private_api/sites.json', { per: 2 }, @env
      MultiJson.load(response.body).should have(2).sites
    end

    it 'supports :with_state scope' do
      get 'private_api/sites.json', { with_state: 'archived' }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site3.token
    end

    it 'supports :created_on scope' do
      get 'private_api/sites.json', { created_on: 2.days.ago }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site3.token
    end

    it 'supports :not_tagged_with scope' do
      get 'private_api/sites.json', { not_tagged_with: 'adult' }, @env
      body = MultiJson.load(response.body)
      body.should have(2).sites
      body[0]['token'].should eq site2.token
      body[1]['token'].should eq site3.token
    end

    it 'supports :select scope' do
      get 'private_api/sites.json', { select: %w[token hostname] }, @env
      video_tag = MultiJson.load(response.body).first
      video_tag.should have_key('token')
      video_tag.should have_key('hostname')
      video_tag.should_not have_key('dev_hostnames')
    end

    it 'supports :without_hostnames scope' do
      get 'private_api/sites.json', { without_hostnames: %w[google.com facebook.com] }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site3.token
    end

    it 'supports :first_billable_plays_on_week scope' do
      get 'private_api/sites.json', { first_billable_plays_on_week: Time.now.utc }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
    end
  end

  describe 'show' do
    it 'finds site per token' do
      get "private_api/sites/#{site1.token}.json", {}, @env
      MultiJson.load(response.body).should_not have_key("site")
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
        response.status.should eq 400
        MultiJson.load(response.body).should eq({ 'error' => 'Missing :tag parameters.' })
      end

      it 'returns a 400 if :tag is nil' do
        put "private_api/sites/#{site1.token}/add_tag.json", { tag: nil }, @env
        response.status.should eq 400
        MultiJson.load(response.body).should eq({ 'error' => 'Missing :tag parameters.' })
      end
    end
  end
end
