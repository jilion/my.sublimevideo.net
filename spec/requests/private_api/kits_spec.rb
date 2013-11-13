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
        expect(response.status).to eq 404
        expect(MultiJson.load(response.body)).to eq({ 'error' => 'Resource could not be found.' })
      end
    end

    it 'supports :per scope' do
      get url, { per: 2 }, @env
      body = MultiJson.load(response.body)
      expect(body.size).to eq(2)
      expect(body[0]['design']).to eq({
        'name' => kit1.design.name
      })
      expect(body[0]['identifier']).to eq kit1.identifier
      expect(body[0]['name']).to eq kit1.name
      expect(body[0]['settings']).to eq kit1.settings
      expect(body[0]['created_at']).to be_present
      expect(body[0]['updated_at']).to be_present
      expect(body[0]['default']).to be_truthy

      expect(body[1]['default']).to be_falsey

      expect(response.status).to eq 200
    end
  end
end
