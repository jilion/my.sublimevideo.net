require 'spec_helper'

describe 'Private API Kits requests' do
  let!(:site) { create(:site) }
  let!(:kit1) { create(:kit, site: site) }
  let!(:kit2) { create(:kit, site: site) }
  let!(:kit3) { create(:kit, site: site) }

  before do
    set_api_credentials
    site.update_column(:default_kit_id, kit1.id)
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'index' do
    let(:url) { "private_api/sites/#{site.to_param}/kits.json" }

    it_behaves_like 'valid caching headers', cache_validation: false

    context 'non existing site' do
      it 'returns 404' do
        get 'private_api/sites/42/addons.json', {}, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => 'Resource could not be found.' })
      end
    end

    it 'supports :per scope' do
      get url, { per: 2 }, @env
      body = MultiJson.load(response.body)
      body.should have(2).kits
      body[0]['design'].should eq({
        'name' => kit1.design.name
      })
      body[0]['identifier'].should eq kit1.identifier
      body[0]['name'].should eq kit1.name
      body[0]['settings'].should eq kit1.settings
      body[0]['created_at'].should be_present
      body[0]['updated_at'].should be_present
      body[0]['default'].should be_true

      body[1]['default'].should be_false

      response.status.should eq 200
    end
  end
end
