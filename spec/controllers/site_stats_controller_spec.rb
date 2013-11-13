require 'spec_helper'

describe SiteStatsController do

  verb_and_actions = { get: [:index] }
  it_behaves_like 'redirect when connected as', 'http://my.test.host/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: '1'
  it_behaves_like 'redirect when connected as', 'http://my.test.host/login', [:guest], verb_and_actions, site_id: '1'

  before { stub_site_stats }

  context 'logged-in' do
    let(:site) { create(:site) }
    before do
      sign_in site.user
    end

    context 'not subscribed to the stats addon' do
      before { allow(site).to receive(:realtime_stats_active?).and_return(false) }
    end

    context 'subscribed to the stats addon' do
      it_behaves_like 'responds to formats', [:html, :js, :csv], :get, [:index] do
        before { expect_any_instance_of(SiteExhibit).to receive(:realtime_stats_active?).and_return(true) }
        let(:params) { { site_id: site.token } }
      end
    end
  end

  context 'with demo site' do
    let(:site) { mock_model(Site, token: SiteToken[:www]) }
    before do
      Site.stub_chain(:where, :first!) { site }
    end

    it 'responds with success to GET :index' do
      get :index, site_id: SiteToken[:www], demo: true

      expect(response).to be_success
    end
  end

end
