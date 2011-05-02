require 'spec_helper'

describe PagesController do

  context "with logged in unsuspended user" do
    before(:each) { sign_in :user, authenticated_user }

    %w[terms privacy].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should render_template("pages/#{page}")
      end
    end

    it "should redirect to root path with GET :show, on suspended page" do
      get :show, :page => 'suspended'
      response.should redirect_to(root_path)
    end
  end

  context "with logged in suspended user" do
    before(:each) { sign_in :user, authenticated_user(:state => 'suspended') }

    %w[terms privacy].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should render_template("pages/#{page}")
      end
    end

    it "should respond with success to GET :show, on suspended page" do
      get :show, :page => 'suspended'
      response.should render_template("pages/suspended")
    end
  end

  context "as guest" do
    %w[terms privacy].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should render_template("pages/#{page}")
      end
    end

    it "should redirect to /sites with GET :show, on suspended page" do
      get :show, :page => 'suspended'
      response.should redirect_to(new_user_session_path)
    end
  end

end