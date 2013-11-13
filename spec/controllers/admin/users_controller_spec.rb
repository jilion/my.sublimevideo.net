require 'spec_helper'

describe Admin::UsersController do

  context "with logged in admin with the god role" do
    before { sign_in :admin, authenticated_admin(roles: ['marcom']) }

    describe "PUT :update" do
      before do
        allow(User).to receive(:find).with('1') { mock_user }
      end

      it "responds with redirect to successful PUT :update" do
        allow(mock_site).to receive(:update) { true }

        put :update, id: '1', user: { name: 'foo' }
        expect(response).to redirect_to(edit_admin_user_url(mock_user))
      end

      it "responds with success to failing PUT :update" do
        allow(mock_site).to receive(:update) { false }

        put :update, id: '1', user: { name: 'foo' }
        expect(response).not_to be_success
        expect(response).to redirect_to(edit_admin_user_url(mock_user))
      end
    end
  end

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :show, :become] }

end
