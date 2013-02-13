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
      Site.stub_chain(:includes, :find_by_token!).with('abc123') { mock_site }

      get :edit, id: 'abc123'
      response.should render_template(:edit)
    end

    describe "PUT :update" do
      before do
        Site.stub(:find_by_token!).with('abc123') { mock_site }
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

    it "responds with redirect to successful PUT :update_app_design_subscription" do
      Site.stub(:find_by_token!).with('abc123') { mock_site }
      App::Design.stub(:find).with('42') { mock_app_design(id: 42, name: 'foo_design', title: 'Foo Design') }
      mock_service = mock('SiteManager')
      SiteManager.stub(:new).with(mock_site) { mock_service }

      mock_service.should_receive(:update_billable_items).with({ 'foo_design' => 42 }, {}, { allow_custom: true })

      put :update_app_design_subscription, id: 'abc123', app_design_id: 42
      response.should redirect_to(edit_admin_site_url(mock_site))
    end
  end

  context "with logged in admin with the marcom role" do
    before { sign_in :admin, authenticated_admin(roles: ['marcom']) }

    describe "PUT :update" do
      before do
        Site.stub(:find_by_token!).with('abc123') { mock_site }
      end

      it "responds with redirect to successful PUT :update" do
        mock_site.should_receive(:update_attributes).with({ 'tag_list' => ['foo'] }, { without_protection: true }) { true }

        put :update, id: 'abc123', site: { accessible_stage: 'beta', tag_list: ['foo'] }
        response.should redirect_to(edit_admin_site_url(mock_site))
      end

      it "responds without success to failing PUT :update" do
        mock_site.should_receive(:update_attributes) { false }

        put :update, id: 'abc123', site: {}
        response.should redirect_to(edit_admin_site_url(mock_site))
      end
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :edit], put: [:update, :update_app_design_subscription, :update_addon_plan_subscription] }
  it_should_behave_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { put: [:update_app_design_subscription, :update_addon_plan_subscription] }

end
