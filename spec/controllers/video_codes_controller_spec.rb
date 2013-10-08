require 'spec_helper'

describe VideoCodesController do

  it_behaves_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], { get: [:new] }, site_id: 'public'
  it_behaves_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended', early_access: ['video']]], { get: [:new] }, site_id: '1'
  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: [:new] }, site_id: '1'

  it_behaves_like "redirect when connected as", 'http://my.test.host/assistant/new-site', [[:user, early_access: []]], { get: [:edit] }, site_id: '1', id: '1'

  context 'user logged-in' do
    before do
      sign_in authenticated_user(early_access: [])
    end

    context "without early access to video" do

      context 'without any site' do
        it "is success when :new, site_id: nil" do
          get :new, site_id: nil
          response.should redirect_to assistant_new_site_path
        end

        it "redirects when :new, site_id: '1'" do
          get :new, site_id: '1'
          response.should redirect_to assistant_new_site_path
        end
      end

      context 'with sites' do
        before do
          @site1 = create(:site, user: @authenticated_user, created_at: 3.days.ago)
          @site2 = create(:site, user: @authenticated_user, created_at: 2.days.ago)
        end

        it "redirects when :new, site_id: nil" do
          get :new, site_id: nil
          response.should redirect_to new_site_video_code_path(@site2.token)
        end

        it "is success when :new, site_id: 'site.token'" do
          get :new, site_id: @site2.token
          response.should be_success
        end
      end
    end

    context "with early access to video" do
      before do
        sign_in authenticated_user(early_access: ['video'])
        @site = create(:site, user: @authenticated_user)
      end

      it "redirects when :new, site_id: nil" do
        get :new, site_id: nil
        response.should redirect_to new_site_video_code_path(@site.token)
      end

      it "is success when :new, site_id: 'site.token'" do
        get :new, site_id: @site.token
        response.should be_success
      end
    end
  end

end
