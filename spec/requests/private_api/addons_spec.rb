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
    describe 'caching strategy' do
      it_behaves_like 'valid caching headers', cache_validation: false do
        let(:url) { "private_api/sites/#{site.to_param}/addons.json" }
        let(:update_record) { -> { site.update_attribute(:hostname, 'example.com') } }
      end
    end

    context 'non existing site' do
      it 'returns 404' do
        get 'private_api/sites/42/addons.json', {}, @env
        response.status.should eq 404
        MultiJson.load(response.body).should eq({ 'error' => 'Resource could not be found.' })
      end
    end

    it 'supports :per scope' do
      get "private_api/sites/#{site.to_param}/addons.json", { per: 2 }, @env
      MultiJson.load(response.body).should have(2).addon_plans
    end

    it 'supports :state scope' do
      get "private_api/sites/#{site.to_param}/addons.json", { state: 'subscribed' }, @env
      body = MultiJson.load(response.body)
      body.should have(1).addon_plan
      body[0]['addon'].should eq({
        'name' => subscribed_addon_plan_billable_item.item.addon_name
      })
      body[0]['name'].should eq subscribed_addon_plan_billable_item.item.name
      body[0]['title'].should eq subscribed_addon_plan_billable_item.item.title
      body[0]['price'].should eq subscribed_addon_plan_billable_item.item.price
      body[0]['availability'].should eq subscribed_addon_plan_billable_item.item.availability
      body[0]['required_stage'].should eq subscribed_addon_plan_billable_item.item.required_stage
      body[0]['stable_at'].should be_present
      body[0]['created_at'].should be_present
      body[0]['updated_at'].should be_present

      response.status.should eq 200
    end
  end
end
