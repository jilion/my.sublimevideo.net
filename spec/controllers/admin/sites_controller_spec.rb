require 'spec_helper'

describe Admin::SitesController do

  context "with logged in admin with the god role" do
    before { sign_in :admin, authenticated_admin(roles: ['god']) }

    it "responds with success to GET :index" do
      get :index
      expect(response).to render_template(:index)
    end

    it "responds with redirect to GET :show" do
      get :show, id: 'abc123'
      expect(response).to redirect_to(edit_admin_site_url('abc123'))
    end

    it "responds with success to GET :edit" do
      Site.stub_chain(:where, :first!) { mock_site }

      get :edit, id: 'abc123'
      expect(response).to render_template(:edit)
    end

    describe "PUT :update" do
      before do
      Site.stub_chain(:where, :first!) { mock_site }
      end

      it "responds with redirect to successful PUT :update" do
        expect(mock_site).to receive(:update).with('mode' => 'beta', 'tag_list' => ['foo']) { true }

        put :update, id: 'abc123', site: { mode: 'beta', tag_list: ['foo'] }
        expect(response).to redirect_to(edit_admin_site_url(mock_site))
      end

      it "responds with success to failing PUT :update" do
        expect(mock_site).to receive(:update) { false }

        put :update, id: 'abc123', site: { mode: 'beta' }
        expect(response).to redirect_to(edit_admin_site_url(mock_site))
      end
    end

    it "responds with redirect to successful PUT :update_design_subscription" do
      Site.stub_chain(:where, :first!) { mock_site }
      allow(Design).to receive(:find).with('42') { mock_design(id: 42, name: 'foo_design', title: 'Foo Design') }
      mock_service = double('SiteManager')
      allow(SiteManager).to receive(:new).with(mock_site) { mock_service }

      expect(mock_service).to receive(:update_billable_items).with({ 'foo_design' => 42 }, {}, { allow_custom: true, force: false })

      put :update_design_subscription, id: 'abc123', design_id: 42
      expect(response).to redirect_to(edit_admin_site_url(mock_site))
    end
  end

  context "with logged in admin with the marcom role" do
    before { sign_in :admin, authenticated_admin(roles: ['marcom']) }

    describe "PUT :update" do
      before { Site.stub_chain(:where, :first!) { mock_site } }

      it "responds with redirect to successful PUT :update" do
        expect(mock_site).to receive(:update).with('tag_list' => ['foo']) { true }

        put :update, id: 'abc123', site: { accessible_stage: 'beta', tag_list: ['foo'] }
        expect(response).to redirect_to(edit_admin_site_url(mock_site))
      end

      it "responds without success to failing PUT :update" do
        expect(mock_site).to receive(:update) { false }

        put :update, id: 'abc123', site: { foo: 'bar' }
        expect(response).to redirect_to(edit_admin_site_url(mock_site))
      end
    end
  end

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :edit], put: [:update, :update_design_subscription, :update_addon_plan_subscription] }
  it_behaves_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { put: [:update_design_subscription, :update_addon_plan_subscription] }

end
