require 'spec_helper'

describe Users::RegistrationsController do
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:user] }

  context "with logged in user" do
    before(:each) { sign_in :user, authenticated_user }

    describe "DELETE :destroy" do

      it "should redirect to /login if password is sent" do
        @current_user.should_receive(:current_password=).with('123456')
        @current_user.should_receive(:archive).and_return(true)

        delete :destroy, :user => { :current_password => '123456' }
        assigns(:user).should be(@current_user)
        response.should redirect_to(new_user_session_url)
      end

      it "should render 'users/registrations/edit' without password" do
        @current_user.should_receive(:current_password=).with('')
        @current_user.should_receive(:archive).and_return(false)

        delete :destroy, :user => { :current_password => '' }
        assigns(:user).should be(@current_user)
        response.should render_template('users/registrations/edit')
      end
    end
  end

  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], { :delete => :destroy }

end
