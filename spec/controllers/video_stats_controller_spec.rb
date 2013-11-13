require 'spec_helper'

describe VideoStatsController do

  it_behaves_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], { get: [:index] }, site_id: '1', video_tag_id: '1'
  it_behaves_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended', early_access: ['video']]], { get: [:index] }, site_id: '1', video_tag_id: '1'
  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: [:index] }, site_id: '1', video_tag_id: '1'

  context 'user logged-in' do
    before do
      sign_in authenticated_user
      @site = create(:site, user: @authenticated_user)
      video_tag = double(uid: '1', site_token: @site.token, sources: [])
      expect(VideoTag).to receive(:find).with('1', _site_token: @site.token) { video_tag }
    end

    context 'not subscribed to stats add-on' do
      before do
        expect_any_instance_of(Site).to receive(:subscribed_to?).and_return(false)
      end

      it 'redirects' do
        get :index, site_id: @site.token, video_tag_id: '1'
        expect(response).to redirect_to root_path
      end
    end

    context 'subscribed to stats add-on' do
      before do
        expect_any_instance_of(Site).to receive(:subscribed_to?).and_return(true)
        expect(VideoStat).to receive(:last_hours_stats) { [] }
      end

      it 'responds with HTML format' do
        get :index, site_id: @site.token, video_tag_id: '1'
        expect(response).to be_success
      end

      it 'responds to CSV format' do
        get :index, site_id: @site.token, video_tag_id: '1', format: 'csv'
        expect(response).to be_success
      end
    end
  end

end
