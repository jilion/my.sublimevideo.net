require 'spec_helper'

describe Admin::UsersController do

  context "with logged in admin with the god role" do
    before { sign_in :admin, authenticated_admin(roles: ['marcom']) }

    describe "PUT :update" do
      before do
        User.stub(:find).with('1') { mock_user }
      end

      it "responds with redirect to successful PUT :update" do
        mock_site.stub(:update) { true }

        put :update, id: '1', user: { foo: 'bar' }
        response.should redirect_to(edit_admin_user_url(mock_user))
      end

      it "responds with success to failing PUT :update" do
        mock_site.stub(:update) { false }

        put :update, id: '1', user: { foo: 'bar' }
        response.should_not be_success
        response.should redirect_to(edit_admin_user_url(mock_user))
      end
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :show, :become] }

end
