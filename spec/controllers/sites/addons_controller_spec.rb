require 'spec_helper'

describe Sites::AddonsController do
  
#   context "with logged in user" do
#     before :each do
#       @mock_user = mock_model(User, :active? => true, :confirmed? => true, :suspended? => false)
#       User.stub(:find).and_return(@mock_user)
#       sign_in :user, @mock_user
#     end
#     
#     it "should respond with success to GET :edit" do
#       @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
#       get :edit, :site_id => '1', :format => :js
#       response.should be_success
#     end
#     it "should respond with success to PUT :update" do
#       @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
#       mock_site.stub(:update_attributes).with({}).and_return(true)
#       mock_site.stub_chain(:delay, :activate).and_return(true)
#       put :update, :site_id => '1', :site => {}, :format => :js
#       response.should be_success
#     end
#   end
#   
#   context "as guest" do
#     it "should respond with redirect to GET :edit" do
#       get :edit, :site_id => '1'
#       response.should redirect_to(new_user_session_path)
#     end
#     it "should respond with redirect to PUT :update" do
#       put :update, :site_id => '1', :site => {}
#       response.should redirect_to(new_user_session_path)
#     end
#   end
#   
# private
#   
#   def mock_site(stubs = {})
#     @mock_site ||= mock_model(Site, stubs)
#   end
  
end