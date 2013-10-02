require 'spec_helper'

describe VideoStatsController do

  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], { get: [:index] }, site_id: 'public'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended', early_access: ['video']]], { get: [:index] }, site_id: '1'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: [:index] }, site_id: '1'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/', [[:user, early_access: []]], { get: [:index] }, site_id: '1', id: '1'

  context 'user logged-in' do
    before do
      sign_in authenticated_user(early_access: [])
    end

    context "without early access to video" do
      context 'without any site' do
        it "redirects when :index, site_id: nil, id: nil" do
          get :index, site_id: nil, id: nil
          response.should redirect_to root_path
        end

        it "redirects when :index, site_id: nil, id: '1'" do
          get :index, site_id: nil, id: '1'
          response.should redirect_to root_path
        end
      end

      context 'with sites' do
        before do
          @site = create(:site, user: @authenticated_user, created_at: 3.days.ago)
        end

        it "redirects when :index, site_id: nil, id: nil" do
          get :index, site_id: @site.token, id: nil
          response.should redirect_to root_path
        end

        it "redirects when :index, site_id: 'site.token', id: nil" do
          get :index, site_id: @site.token, id: '1'
          response.should redirect_to root_path
        end
      end
    end
  end

  context "with early access to video" do
    before do
      sign_in authenticated_user(early_access: ['video'])
      @site = create(:site, user: @authenticated_user)
      video_tag = double(uid: '1', site_token: @site.token, sources: [])
      expect(VideoTag).to receive(:find).with('1', _site_token: @site.token) { video_tag }
    end

    context 'not subscribed to stats add-on' do
      before do
        expect_any_instance_of(Site).to receive(:subscribed_to?).and_return(false)
      end

      it 'redirects' do
        get :index, site_id: @site.token, id: '1'
        response.should redirect_to root_path
      end
    end

    context 'subscribed to stats add-on' do
      before do
        expect_any_instance_of(Site).to receive(:subscribed_to?).and_return(true)
        expect(VideoStat).to receive(:last_hours_stats) { [] }
      end

      it "is success when :index, site_id: 'site.token', id: '1'" do
        get :index, site_id: @site.token, id: '1'
        response.should be_success
      end

      it "is success when :index, site_id: 'site.token', id: '1'" do
        get :index, site_id: @site.token, id: '1', format: 'csv'
        response.should be_success
      end
    end
  end

end
