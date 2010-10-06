require 'spec_helper'

describe TicketsController do
  include Devise::TestHelpers
  
  context "as logged in user" do
    before(:each) do
      sign_in :user, logged_in_user
      logged_in_user.stub!(:full_name).and_return("John Doe")
      logged_in_user.stub!(:email).and_return("john@doe.com")
      User.stub(:find) { logged_in_user }
    end
    
    describe "GET new" do
      it "assigns a new ticket as @ticket" do
        Ticket.stub(:new) { mock_ticket }
        
        get :new
        assigns(:ticket).should be(mock_ticket)
      end
    end
    
    describe "POST create" do
      describe "with valid params" do
        let(:params) { { :type => "bug-report", :subject => "Subject", :message => "Message" } }
        
        before(:each) do
          Ticket.stub(:new) { mock_ticket }
          mock_ticket.stub!(:save).and_return(true)
        end
        
        it "should assign a newly created ticket as @ticket" do
          post :create, :ticket => params
          assigns(:ticket).should be(mock_ticket)
        end
        
        it "should respond with redirect" do
          post :create, :ticket => params
          response.should redirect_to(new_ticket_url)
        end
      end
      
      describe "with invalid params" do
        it "should render new template" do
          post :create, :ticket => { :type => "foo", :subject => "Subject", :message => "Message" }
          response.should be_success
          response.should render_template("new")
        end
        it "should render new template" do
          post :create, :ticket => { :type => "bug-report", :subject => "", :message => "Message" }
          response.should be_success
          response.should render_template("new")
        end
        it "should render new template" do
          post :create, :ticket => { :type => "bug-report", :subject => "Subject", :message => "" }
          response.should be_success
          response.should render_template("new")
        end
      end
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_user_session_path)
    end
    
    it "should respond with redirect to POST :create" do
      post :create, :ticket => { :type => "request", :subject => "Subject", :message => "Message" }
      response.should redirect_to(new_user_session_path)
    end
  end
  
end