require 'spec_helper'

describe 'Private API Sites requests' do
  let!(:design) do
    create(:design, name: 'classic')
    create(:design, name: 'light')
    create(:design, name: 'flat')
  end
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
      MultiJson.load(response.body).should have(2).sites
    end

    it 'supports :not_archived scope' do
      get url, { not_archived: true }, @env
      body = MultiJson.load(response.body)
      body.should have(2).sites
      body[0]['token'].should eq site1.token
      body[1]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :created_on scope' do
      get url, { created_on: 2.days.ago }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :not_tagged_with scope' do
      get url, { not_tagged_with: 'adult' }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :select scope' do
      get url, { select: %w[token hostname] }, @env
      video_tag = MultiJson.load(response.body).first
      video_tag.should have_key('token')
      video_tag.should have_key('hostname')
      video_tag.should_not have_key('dev_hostnames')
      response.status.should eq 200
    end

    it 'supports :without_hostnames scope' do
      get url, { without_hostnames: %w[google.com facebook.com] }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :first_admin_starts_on_week scope' do
      get url, { first_admin_starts_on_week: Time.now.utc }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
      response.status.should eq 200
    end

    it 'supports :user_id scope' do
      get url, { user_id: site1.user_id }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site1.token
      response.status.should eq 200
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
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => 'Resource could not be found.' })
      end
    end

    context 'existing site' do
      it 'finds site per token' do
        get url, {}, @env
        body = MultiJson.load(response.body)
        body['token'].should eq site1.token
        body['tags'].should eq ['adult']
        body['default_kit']['identifier'].should eq site1.default_kit.identifier
        body['default_kit']['name'].should eq site1.default_kit.name
        body['default_kit']['settings'].should eq site1.default_kit.settings
        body['default_kit']['design']['name'].should eq site1.default_kit.design.name
        response.status.should eq 200
      end
    end

    context 'site belongs to given user' do
      it 'supports :user_id scope' do
        get url, { user_id: site1.user_id }, @env
        body = MultiJson.load(response.body)
        body['token'].should eq site1.token
        response.status.should eq 200
      end
    end

    context 'site do not belong to given user' do
      it 'returns 404' do
        get url, { user_id: site2.user_id }, @env
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
  end
end
