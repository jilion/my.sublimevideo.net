require 'spec_helper'

describe Admin::EnthusiastsController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before :each do
      @mock_admin = mock_model(Admin, :active? => true, :confirmed? => true)
      Admin.stub(:find).and_return(@mock_admin)
      sign_in :admin, @mock_admin
    end
    
    it "should respond with success to GET :index" do
      Enthusiast.stub(:includes).and_return([])
      get :index
      response.should be_success
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
  end
  
private
  
  def mock_enthusiast(stubs={})
    @mock_enthusiast ||= mock_model(Enthusiast, stubs)
  end
  
end