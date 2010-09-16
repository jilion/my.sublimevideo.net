require 'spec_helper'

describe Api::InvitationsController do
  include Devise::TestHelpers
  
  context "with good api token in header" do
    before :each do
      ENV['API_TOKEN'] = "bob"
      request.env['TOKEN'] = ENV['API_TOKEN']
    end
    
    it "should respond with success to post :create" do
      User.should_receive(:invite).with('email' => 'john@doe.com').and_return(mock_user(:invited? => true))
      post :create, :invitation => { :email => 'john@doe.com' }
      response.should be_success
      response.status.should == 201
    end
    
    it "should not respond with success to post :create if email not valid" do
      post :create, :invitation => {}
      response.should_not be_success
      response.status.should == 422
    end
    
    it "should set enthusiast_id" do
      post :create, :invitation => { :email => 'John@doe.com', :enthusiast_id => "33" }
      invited = User.last
      invited.should be_invited
      invited.email.should == 'john@doe.com'
      invited.enthusiast_id.should == 33
    end
    
    it "should not create duplicated user" do
      user = Factory(:user, :email => 'john@doe.com')
      post :create, :invitation => { :email => 'John@doe.com' }
      response.should_not be_success
    end
  end
  
  context "as guest" do
    
    it "should respond with redirect to GET :index" do
      post :create, :invitation => { :email => 'john@doe.com' }
      response.should_not be_success
      response.status.should == 401
    end
  end
  
private
  
  def mock_user(stubs={})
    @mock_user ||= mock_model(User, stubs)
  end
  
end