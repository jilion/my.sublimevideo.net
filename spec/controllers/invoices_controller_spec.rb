require 'spec_helper'

describe InvoicesController do
  
  context "with a logged in user" do
    before(:each) do
      sign_in :user, authenticated_user
      @current_user.stub_chain(:invoices, :find_by_token).with('QWE123TYU') { mock_invoice }
    end
    
    it "should respond with success on GET :current" do
      Invoice.should_receive(:build).with(:user => @current_user, :started_at => Time.now.utc.beginning_of_month, :ended_at => Time.now.utc.end_of_month) { mock_invoice }
      
      get :current
      response.should be_success
    end
    
    it "should respond with success on GET :show" do
      get :show, :id => 'QWE123TYU'
      response.should be_success
    end
  end
  
  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :current, :get => :show }
  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], { :get => :current, :get => :show }
  
end