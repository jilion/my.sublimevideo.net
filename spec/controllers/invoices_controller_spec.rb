require 'spec_helper'

describe InvoicesController do

  context "with a logged in user" do
    before(:each) do
      sign_in :user, authenticated_user
    end

    describe "GET :index" do
      it "should render :index with 'application' layout" do
        authenticated_user.stub_chain(:sites, :find_by_token).and_return(mock_site)
        mock_site.should_receive(:invoices).and_return([mock_invoice])
        get :index, :site_id => '1'
        assigns(:site).should == mock_site
        assigns(:invoices).should == [mock_invoice]
        response.should render_template('layouts/application')
        response.should render_template(:index)
      end
    end

    describe "GET :show" do
      it "should render :show" do
        authenticated_user.stub_chain(:invoices, :find_by_reference).with('QWE123TYU').and_return(mock_invoice)

        get :show, :id => 'QWE123TYU'
        assigns(:invoice).should == mock_invoice
        response.should render_template('layouts/invoices')
        response.should render_template(:show)
      end
    end

    describe "PUT :pay" do
      it "should respond with redirect" do
        authenticated_user.stub_chain(:invoices, :failed, :find_by_reference).with('QWE123TYU') { mock_invoice }
        mock_invoice.should_receive(:retry)
        post :pay, :id => 'QWE123TYU'
        assigns(:invoice).should == mock_invoice
        response.should redirect_to(page_path('suspended'))
      end
    end
  end

  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], { :get => :index }, :site_id => "1"
  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :index }, :site_id => "1"
  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :show, :put => :pay }

end
