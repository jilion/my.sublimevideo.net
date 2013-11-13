require 'spec_helper'

describe 'Private API Sites requests', :addons do
  let!(:site1) do
    manager = SiteManager.new(build(:site, created_at: 3.days.ago, hostname: 'google.com', updated_at: Time.utc(2013, 4, 25)))
    manager.create
    manager.site.tag_list << 'adult'; manager.site.save!
    manager.site
  end
  let!(:site2) do
    manager = SiteManager.new(build(:site, created_at: 2.days.ago, first_admin_starts_on: Time.now.utc, updated_at: Time.utc(2013, 4, 26)))
    manager.create
    manager.site
  end
  let!(:site3) do
    manager = SiteManager.new(build(:site, created_at: 2.days.ago))
    manager.create
    manager.site.archive!
    manager.site
  end

  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'index' do
    let(:url) { 'private_api/sites.json' }

    it_behaves_like 'valid caching headers', cache_validation: false

    it 'supports :per scope' do
      get url, { per: 2 }, @env
      expect(MultiJson.load(response.body).size).to eq(2)
    end

    it 'supports :not_archived scope' do
      get url, { not_archived: true }, @env
      body = MultiJson.load(response.body)
      expect(body.size).to eq(2)
      expect(body[0]['token']).to eq site1.token
      expect(body[1]['token']).to eq site2.token
      expect(response.status).to eq 200
    end

    it 'supports :created_on scope' do
      get url, { created_on: 2.days.ago }, @env
      body = MultiJson.load(response.body)
      expect(body.size).to eq(1)
      expect(body[0]['token']).to eq site2.token
      expect(response.status).to eq 200
    end

    it 'supports :not_tagged_with scope' do
      get url, { not_tagged_with: 'adult' }, @env
      body = MultiJson.load(response.body)
      expect(body.size).to eq(1)
      expect(body[0]['token']).to eq site2.token
      expect(response.status).to eq 200
    end

    it 'supports :select scope' do
      get url, { select: %w[token hostname] }, @env
      video_tag = MultiJson.load(response.body).first
      expect(video_tag).to have_key('token')
      expect(video_tag).to have_key('hostname')
      expect(video_tag).not_to have_key('dev_hostnames')
      expect(response.status).to eq 200
    end

    it 'supports :without_hostnames scope' do
      get url, { without_hostnames: %w[google.com facebook.com] }, @env
      body = MultiJson.load(response.body)
      expect(body.size).to eq(1)
      expect(body[0]['token']).to eq site2.token
      expect(response.status).to eq 200
    end

    it 'supports :first_admin_starts_on_week scope' do
      get url, { first_admin_starts_on_week: Time.now.utc }, @env
      body = MultiJson.load(response.body)
      expect(body.size).to eq(1)
      expect(body[0]['token']).to eq site2.token
      expect(response.status).to eq 200
    end

    it 'supports :by_last_30_days_admin_starts scope' do
      get url, { by_last_30_days_admin_starts: 'desc' }, @env
      expect(MultiJson.load(response.body).size).to eq(2)
      expect(response.status).to eq 200
    end

    it 'supports :by_last_30_days_starts scope' do
      get url, { by_last_30_days_starts: 'desc' }, @env
      expect(MultiJson.load(response.body).size).to eq(2)
      expect(response.status).to eq 200
    end

    it 'supports :user_id scope' do
      get url, { user_id: site1.user_id }, @env
      body = MultiJson.load(response.body)
      expect(body.size).to eq(1)
      expect(body[0]['token']).to eq site1.token
      expect(response.status).to eq 200
    end
  end

  describe "tokens" do
    let(:url) { 'private_api/sites/tokens.json' }

    it_behaves_like 'valid caching headers', cache_validation: false

    it 'supports :with_addon_plan scope' do
      get url, { with_addon_plan: 'stats-realtime' }, @env
      body = MultiJson.load(response.body)
      expect(body).to eq []
      expect(response.status).to eq 200
    end
  end

  describe 'show' do
    let(:url) { "private_api/sites/#{site1.token}.json" }

    it_behaves_like 'valid caching headers' do
      let(:record) { site1 }
    end

    context 'non existing site' do
      it 'returns 404' do
        get 'private_api/sites/42.json', {}, @env
        expect(response.status).to eq 404
        expect(MultiJson.load(response.body)).to eq({ 'error' => 'Resource could not be found.' })
      end
    end

    context 'existing site' do
      it 'finds site per token' do
        get url, {}, @env
        body = MultiJson.load(response.body)
        expect(body['token']).to eq site1.token
        expect(body['tags']).to eq ['adult']
        expect(body['default_kit']['identifier']).to eq site1.default_kit.identifier
        expect(body['default_kit']['name']).to eq site1.default_kit.name
        expect(body['default_kit']['settings']).to eq site1.default_kit.settings
        expect(body['default_kit']['design']['name']).to eq site1.default_kit.design.name
        expect(response.status).to eq 200
      end
    end

    context 'site belongs to given user' do
      it 'supports :user_id scope' do
        get url, { user_id: site1.user_id }, @env
        body = MultiJson.load(response.body)
        expect(body['token']).to eq site1.token
        expect(response.status).to eq 200
      end
    end

    context 'site do not belong to given user' do
      it 'returns 404' do
        get url, { user_id: site2.user_id }, @env
        expect(response.status).to eq 404
        expect(MultiJson.load(response.body)).to eq({ 'error' => 'Resource could not be found.' })
      end
    end
  end

  describe 'add_tag' do
    it 'adds tag to site' do
      put "private_api/sites/#{site2.token}/add_tag.json", { tag: 'adult' }, @env

      expect(site2.tag_list).to include('adult')
      expect(response.status).to eq 204
    end
  end
end
