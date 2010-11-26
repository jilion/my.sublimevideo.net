require 'spec_helper'

describe InvoicesController do
  
  context "with a logged in user" do
    before(:each) do
      sign_in :user, authenticated_user
      @current_user.stub_chain(:invoices, :find_by_reference).with('QWE123TYU') { mock_invoice }
    end
    
    it "should respond with success on GET :usage" do
      Timecop.freeze(Time.utc(2010,1,15)) do
        Invoice.should_receive(:build).with(:user => @current_user, :started_at => Time.utc(2010,1,1), :ended_at => Time.utc(2010,1,15)) { mock_invoice }
        
        get :usage
      end
      response.should be_success
    end
    
    it "should respond with success on GET :show" do
      get :show, :id => 'QWE123TYU'
      response.should be_success
    end
  end
  
  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :usage, :get => :show }
  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], { :get => :usage, :get => :show }
  
end