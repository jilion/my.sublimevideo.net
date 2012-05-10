require 'spec_helper'

describe Admin::SitesController do

  context "with logged in admin with the god role" do
    before { sign_in :admin, authenticated_admin(roles: ['god']) }

    it "responds with success to GET :index" do
      get :index
      response.should render_template(:index)
    end

    it "responds with redirect to GET :show" do
      get :show, id: 'abc123'
      response.should redirect_to(edit_admin_site_url('abc123'))
    end

    it "responds with success to GET :edit" do
      Site.stub_chain(:includes, :find_by_token).with('abc123') { mock_site }

      get :edit, id: 'abc123'
      response.should render_template(:edit)
    end

    describe "PUT :update" do
      before do
        Site.stub(:find_by_token).with('abc123') { mock_site }
      end

      it "responds with redirect to successful PUT :update" do
        mock_site.should_receive(:update_attributes).with({ 'mode' => 'beta', 'tag_list' => ['foo'] }, { without_protection: true }) { true }

        put :update, id: 'abc123', site: { mode: 'beta', tag_list: ['foo'] }
        response.should redirect_to(edit_admin_site_url(mock_site))
      end

      it "responds with success to failing PUT :update" do
        mock_site.should_receive(:update_attributes) { false }

        put :update, id: 'abc123', site: {}
        response.should redirect_to(edit_admin_site_url(mock_site))
      end
    end

    it "responds with redirect to successful PUT :sponsor" do
      Site.stub(:find_by_token).with('abc123') { mock_site }

      mock_site.stub(:sponsor!) { true }

      put :sponsor, id: 'abc123', site: {}
      response.should redirect_to(admin_site_url(mock_site))
    end
  end

  context "with logged in admin with the marcom role" do
    before { sign_in :admin, authenticated_admin(roles: ['marcom']) }

    describe "PUT :update" do
      before do
        Site.stub(:find_by_token).with('abc123') { mock_site }
      end

      it "responds with redirect to successful PUT :update" do
        mock_site.should_receive(:update_attributes).with({ 'tag_list' => ['foo'] }, { without_protection: true }) { true }

        put :update, id: 'abc123', site: { mode: 'beta', tag_list: ['foo'] }
        response.should redirect_to(edit_admin_site_url(mock_site))
      end

      it "responds without success to failing PUT :update" do
        mock_site.should_receive(:update_attributes) { false }

        put :update, id: 'abc123', site: {}
        response.should redirect_to(edit_admin_site_url(mock_site))
      end
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :edit], put: [:update, :sponsor] }
  it_should_behave_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { put: [:sponsor] }

end
