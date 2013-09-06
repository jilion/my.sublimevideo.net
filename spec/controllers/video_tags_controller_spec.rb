require 'spec_helper'

describe VideoTagsController do

  verb_and_actions = { get: [:show], get: [:index] }
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: '1', id: '2'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], verb_and_actions, site_id: '1', id: '2'

  it_should_behave_like "redirect when connected as", 'http://my.test.host/', [[:user, early_access: []]], { get: [:index] }, site_id: '1'

  describe "#index" do
    let(:user) { create(:user) }
    let(:site) { create(:site, user: user ) }
    before { sign_in user }

    context "with last_90_days_active filter, by_last_days_starts sort and page params" do
      it "calls VideoTag.all with good params" do
        expect(VideoTag).to receive(:all).with(hash_including("last_90_days_active" => true, "by_last_90_days_starts" => "desc", page: '2')) { [] }
        get :index, { site_id: site.token, filter: 'last_90_days_active', by_last_days_starts: 'desc', page: '2', early_access: 'video' }, format: :json
        expect(response).to be_success
      end
    end
  end

  describe "#show" do
    context "with demo site" do
      let(:site) { mock_model(Site, token: SiteToken[:www]) }
      before { Site.stub_chain(:where, :first!) { site } }

      it "responds with success to GET :show" do
        VideoTag.stub(:find).with('2', _site_token: site.token)
        get :show, site_id: 'demo', id: '2', format: :json
        expect(response).to be_success
      end
    end
  end

end
