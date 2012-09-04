require 'spec_helper'

describe VideoCodesController do

  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], { get: [:new] }, site_id: 'public'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended', early_access: ['video']]], { get: [:new] }, site_id: '1'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: [:new] }, site_id: '1'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/video-code-generator', [[:user]], { get: [:new] }, site_id: '1'

  it_should_behave_like "redirect when connected as", 'http://my.test.host/sites/new', [[:user, early_access: []]], { get: [:show] }, site_id: '1', id: '1'


  context "without early access to video" do
    before do
      sign_in authenticated_user(early_access: [])
      @site = create(:site, user: @authenticated_user)
    end

    it "is success when :new, site_id: 'public'" do
      get :new, site_id: 'public'
      response.should be_success
    end

    it "redirects when :new, site_id: 'site.token'" do
      get :new, site_id: @site.token
      response.should redirect_to video_code_generator_path
    end
  end

  context "with early access to video" do
    before do
      sign_in authenticated_user(early_access: ['video'])
      @site = create(:site, user: @authenticated_user)
    end

    it "redirects when :new, site_id: 'public'" do
      get :new, site_id: 'public'
      response.should redirect_to new_site_video_code_path(@site.token)
    end

    it "is success when :new, site_id: 'site.token'" do
      get :new, site_id: @site.token
      response.should be_success
    end
  end

end
