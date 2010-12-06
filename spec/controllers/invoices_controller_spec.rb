require 'spec_helper'

describe InvoicesController do
  
  context "with a logged in user" do
    before(:each) do
      sign_in :user, authenticated_user
    end
    
    it "should respond with success on GET :usage" do
      Timecop.freeze(Time.utc(2010,1,15)) do
        Invoice.should_receive(:build).with(:user => @current_user, :started_at => Time.utc(2010,1,1), :ended_at => Time.utc(2010,1,15)) { mock_invoice }
        
        get :usage
      end
      response.should be_success
    end
    
    it "should respond with success on GET :show" do
      @current_user.stub_chain(:invoices, :find_by_reference).with('QWE123TYU') { mock_invoice }
      
      get :show, :id => 'QWE123TYU'
      response.should be_success
    end
    
    it "should respond with redirect on POST :pay" do
      @current_user.stub_chain(:invoices, :failed, :find_by_reference).with('QWE123TYU') { mock_invoice }
      mock_invoice.should_receive(:retry)
      
      post :pay, :id => 'QWE123TYU'
      response.should redirect_to(page_path('suspended'))
    end
  end
  
  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => [:usage, :show], :post => :pay }
  
end