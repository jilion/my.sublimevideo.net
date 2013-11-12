require 'spec_helper'

describe VideoTagsController do

  verb_and_actions = { get: [:show], get: [:index] }
  it_behaves_like 'redirect when connected as', 'http://my.test.host/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: '1', id: '2'
  it_behaves_like 'redirect when connected as', 'http://my.test.host/login', [:guest], verb_and_actions, site_id: '1', id: '2'

  context 'logged-in' do
    let(:user) { create(:user) }
    let(:site) { create(:site, user: user) }
    before do
      sign_in user
      VideoTag.stub(:all).and_return([])
      VideoTag.stub(:find).and_return(double('VideoTag'))
    end

    context "with last_90_days_active filter, by_last_days_starts sort and page params" do
      it "calls VideoTag.all with good params" do
        expect(VideoTag).to receive(:all).with(hash_including("last_90_days_active" => true, "by_last_90_days_starts" => "desc", page: '2')) { [] }
        get :index, { site_id: site.token, filter: 'last_90_days_active', by_last_days_starts: 'desc', page: '2', early_access: 'video' }, format: :json

        expect(response).to be_success
      end
    end

    describe '#show' do
      it_behaves_like 'responds to formats', [:json], :get, [:show] do
        let(:params) { { site_id: site.token, id: '2' } }
      end

      it 'calls VideoTag.find with good params' do
        expect(VideoTag).to receive(:find).with('2', _site_token: site.token).and_return(double('VideoTag'))
        get :show, site_id: site.token, id: '2', format: :json
      end
    end
  end

end
