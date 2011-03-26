require 'spec_helper'

describe Users::SessionsController do

  # context "with non-logged in user" do
  #   describe "GET :new" do
  #     it "should render :edit" do
  #       get :new
  #       response.should render_template(:new)
  #     end
  #   end
  # end
  # 
  # context "with logged in user" do
  #   before :each do
  #     sign_in :user, authenticated_user
  #   end
  # 
  #   describe "GET :new" do
  #     it "should render :edit" do
  #       get :new
  #       flash[:notice].should be_nil
  #       flash[:alert].should be_nil
  #       response.should redirect_to(root_path)
  #     end
  #   end
  # 
  #   describe "GET :destroy" do
  #     before(:each) do
  #       authenticated_user.stub_chain(:sites, :find_by_token).with('a1b2c3').and_return(@mock_site = mock_site)
  #     end
  # 
  #     it "should redirect to /sites when update_attributes succeeds" do
  #       authenticated_user.should_receive(:logout)
  # 
  #       delete :destroy
  #       flash[:notice].should be_nil
  #       flash[:alert].should be_nil
  #       response.should redirect_to new_user_sessions_path
  #     end
  #   end
  # end

end
