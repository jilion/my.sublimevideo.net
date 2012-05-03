require 'spec_helper'

describe Admin::UsersController do

  context "with logged in admin with the god role" do
    before { sign_in :admin, authenticated_admin(roles: ['marcom']) }

    describe "PUT :update" do
      before do
        User.stub(:find).with('1') { mock_user }
      end

      it "responds with redirect to successful PUT :update" do
        mock_user.stub(:vip=) { true }
        mock_user.stub(:save!) { true }

        put :update, id: '1', user: {}
        response.should redirect_to(admin_user_url(mock_user))
      end

      it "responds with success to failing PUT :update" do
        mock_user.stub(:vip=) { true }
        mock_user.stub(:save!) { false }
        mock_user.should_receive(:errors).any_number_of_times.and_return(["error"])

        put :update, id: '1', user: {}
        response.should be_success
        response.should render_template(:edit)
      end
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :show, :become] }

end
