require 'spec_helper'

describe 'Private API Add-ons requests' do
  let!(:site) { create(:site) }
  let!(:trial_addon_plan_billable_item) { create(:addon_plan_billable_item, site: site, state: 'trial') }
  let!(:subscribed_addon_plan_billable_item) { create(:addon_plan_billable_item, site: site, state: 'subscribed') }
  let!(:sponsored_addon_plan_billable_item) { create(:addon_plan_billable_item, site: site, state: 'sponsored') }

  before do
    set_api_credentials
    @env['HTTP_HOST'] = 'my.sublimevideo.dev'
  end

  describe 'index' do
    let(:url) { "private_api/sites/#{site.to_param}/addons.json" }

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
      expect(MultiJson.load(response.body).size).to eq(2)
    end

    it 'supports :state scope' do
      get url, { state: 'subscribed' }, @env
      body = MultiJson.load(response.body)
      expect(body.size).to eq(1)
      expect(body[0]['addon']).to eq({
        'name' => subscribed_addon_plan_billable_item.item.addon_name
      })
      expect(body[0]['name']).to eq subscribed_addon_plan_billable_item.item.name
      expect(body[0]['title']).to eq subscribed_addon_plan_billable_item.item.title
      expect(body[0]['price']).to eq subscribed_addon_plan_billable_item.item.price
      expect(body[0]['availability']).to eq subscribed_addon_plan_billable_item.item.availability
      expect(body[0]['required_stage']).to eq subscribed_addon_plan_billable_item.item.required_stage
      expect(body[0]['stable_at']).to be_present
      expect(body[0]['created_at']).to be_present
      expect(body[0]['updated_at']).to be_present

      expect(response.status).to eq 200
    end
  end
end
