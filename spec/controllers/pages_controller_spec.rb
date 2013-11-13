require 'spec_helper'

describe PagesController do
  before do
    @request.host = 'my.test.host'
  end

  context "with logged in unsuspended user" do
    before { sign_in :user, authenticated_user }

    %w[terms privacy help].each do |page|
      it "responds with success to GET :show, on #{page} page" do
        get :show, page: page
        expect(response).to render_template("pages/#{page}")
      end
    end

    it "should redirect to root path with GET :show, on suspended page" do
      get :show, page: 'suspended'
      expect(response).to redirect_to(root_path)
    end
  end

  context "with logged in suspended user" do
    before { sign_in :user, authenticated_user(state: 'suspended') }

    %w[terms privacy help].each do |page|
      it "responds with success to GET :show, on #{page} page" do
        get :show, page: page
        expect(response).to render_template("pages/#{page}")
      end
    end

    it "responds with success to GET :show, on suspended page" do
      get :show, page: 'suspended'
      expect(response).to render_template("pages/suspended")
    end
  end

  context "as guest" do
    %w[terms privacy].each do |page|
      it "responds with success to GET :show, on #{page} page" do
        get :show, page: page
        expect(response).to render_template("pages/#{page}")
      end
    end

    it "should redirect to the login with GET :show, on suspended page" do
      get :show, page: 'suspended'
      expect(response).to redirect_to('http://my.test.host/login')
    end

    it "should redirect to the login page with GET :help" do
      get :show, page: 'help'
      expect(response).to redirect_to('http://my.test.host/login')
    end
  end

end
