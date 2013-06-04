require 'spec_helper'

describe 'Private API Kits requests' do
  let!(:site) { create(:site) }
  let!(:kit1) { create(:kit, site: site) }
  let!(:kit2) { create(:kit, site: site) }
  let!(:kit3) { create(:kit, site: site) }

  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'index' do
    describe 'caching strategy' do
      it_behaves_like 'valid caching headers', cache_validation: false do
        let(:url) { "private_api/sites/#{site.to_param}/kits.json" }
        let(:update_record) { -> { site.update_attribute(:hostname, 'example.com') } }
      end
    end

    it 'supports :per scope' do
      get "private_api/sites/#{site.to_param}/kits.json", { per: 2 }, @env
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

      response.status.should eq 200
    end
  end
end
