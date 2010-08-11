require 'spec_helper'

describe TicketsController do
  include Devise::TestHelpers
  
  context "as logged in user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true, :suspended? => false)
      User.stub(:find).and_return(@mock_user)
      @mock_user.stub!(:full_name).and_return("John Doe")
      @mock_user.stub!(:email).and_return("john@doe.com")
      sign_in :user, @mock_user
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
        it "assigns a newly created ticket as @ticket" do
          post :create, :ticket => { :type => "billing", :subject => "Subject", :description => "Description" }
          response.should redirect_to(new_ticket_url)
        end
      end
      
      describe "with invalid params" do
        it "assigns a newly created but unsaved ticket as @ticket" do
          post :create, :ticket => { :type => "foo", :subject => "Subject", :description => "Description" }
          response.should render_template("new")
        end
        it "assigns a newly created but unsaved ticket as @ticket" do
          post :create, :ticket => { :type => "billing", :subject => "", :description => "Description" }
          response.should render_template("new")
        end
        it "assigns a newly created but unsaved ticket as @ticket" do
          post :create, :ticket => { :type => "billing", :subject => "Subject", :description => "" }
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
      post :create, :ticket => { :type => "billing", :subject => "Subject", :description => "Description" }
      response.should redirect_to(new_user_session_path)
    end
  end
  
private
  
  def mock_ticket(stubs = {})
    @mock_ticket ||= mock_model(Ticket, stubs).as_null_object
  end
  
end