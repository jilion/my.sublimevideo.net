require 'spec_helper'

describe InvoicesController do

  context "with a logged in user" do
    before(:each) do
      sign_in :user, authenticated_user
    end

    describe "GET :index" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :not_archived, :find_by_token!).with('QWE123TYU').and_return(mock_site)
        mock_site.stub_chain(:invoices, :not_canceled).and_return([mock_invoice])
      end

      it "should render :index with 'application' layout" do
        get :index, :site_id => 'QWE123TYU'
        assigns(:site).should == mock_site
        assigns(:invoices).should == [mock_invoice]
        response.should render_template('layouts/application')
        response.should render_template(:index)
      end
    end

    describe "GET :show" do
      before(:each) do
        authenticated_user.stub_chain(:invoices, :not_canceled, :find_by_reference!).with('QWE123TYU').and_return(mock_invoice)
      end

      it "should render :show" do
        get :show, :id => 'QWE123TYU'
        assigns(:invoice).should == mock_invoice
        response.should render_template('layouts/invoices')
        response.should render_template(:show)
      end
    end

    describe "PUT :retry" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :not_archived, :find_by_token!).and_return(mock_site)
      end
      
      context "no failed invoices" do
        before(:each) do
          mock_site.stub_chain(:invoices, :open_or_failed).and_return(@mock_invoices = [])
          mock_site.should_receive(:to_param) { 'QWE123TYU' }
        end

        it "should create a notice and redirect" do
          @mock_invoices.should_receive(:present?) { false }
          post :retry, :site_id => 'QWE123TYU'
          assigns(:invoices).should == []
          flash[:notice].should == I18n.t("site.invoices.no_invoices_to_retry")
          response.should redirect_to(site_invoices_url(site_id: 'QWE123TYU'))
        end
      end

      context "with failed invoices, retry succeeds" do
        before(:each) do
          mock_site.stub_chain(:invoices, :open_or_failed).and_return([mock_invoice])
          mock_site.should_receive(:to_param) { 'QWE123TYU' }
        end

        it "should create a notice and redirect" do
          Transaction.should_receive(:charge_by_invoice_ids).and_return(mock_transaction(:paid? => true))

          post :retry, :site_id => 'QWE123TYU'
          assigns(:invoices).should == [mock_invoice]
          flash[:notice].should == I18n.t("site.invoices.retry_succeed")
          response.should redirect_to(site_invoices_url(site_id: 'QWE123TYU'))
        end
      end

      context "with failed invoices, retry fails" do
        before(:each) do
          mock_site.stub_chain(:invoices, :open_or_failed).and_return([mock_invoice])
          mock_site.should_receive(:to_param) { 'QWE123TYU' }
        end

        it "should create a notice and redirect" do
          Transaction.should_receive(:charge_by_invoice_ids).and_return(mock_transaction(:paid? => false, :state => "failed"))

          post :retry, :site_id => 'QWE123TYU'
          assigns(:invoices).should == [mock_invoice]
          flash[:alert].should == I18n.t("transaction.errors.failed")
          response.should redirect_to(site_invoices_url(site_id: 'QWE123TYU'))
        end
      end
    end
  end

  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], { :get => :index }, :site_id => "1"
  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :index, :put => :retry }, :site_id => "1"
  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :show }

end
