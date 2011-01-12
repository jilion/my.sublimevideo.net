require 'spec_helper'

describe Admin::InvoicesController do

  context "with logged in admin" do
    before :each do
      sign_in :admin, authenticated_admin
    end

    it "should respond with success to GET :index" do
      get :index
      response.should be_success
      response.should render_template(:index)
    end

    it "should respond with redirect to GET :show" do
      Invoice.stub_chain(:includes, :find_by_reference).with('abc123') { mock_invoice }
      
      get :show, id: 'abc123'
      response.should be_success
      response.should render_template(:show)
    end

    it "should respond with success to GET :edit" do
      Invoice.stub_chain(:includes, :find_by_reference).with('abc123') { mock_invoice }

      get :edit, id: 'abc123'
      response.should be_success
      response.should render_template(:edit)
    end

    describe "PUT :retry_charging" do
      before(:each) do
        Invoice.stub(:find_by_reference).with('abc123') { mock_invoice }
      end

      it "should delay the payment of the invoice" do
        mock_invoice.should_receive(:retry)

        put :retry_charging, id: 'abc123'
        response.should redirect_to(admin_invoices_url)
      end
    end

    describe "PUT :cancel_charging" do
      before(:each) do
        Invoice.stub(:find_by_reference).with('abc123') { mock_invoice }
      end

      it "should delete the Delayed job corresponding to the invoice's charging_delayed_job_id and respond with redirect" do
        mock_invoice.should_receive(:charging_delayed_job) { mock_delayed_job }
        mock_delayed_job.should_receive(:destroy)
        mock_invoice.should_receive(:update_attribute).with(:charging_delayed_job_id, nil)

        put :cancel_charging, id: 'abc123'
        response.should redirect_to(admin_invoices_url)
      end
    end
  end

  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { get: [:index, :edit], post: :retry_charging, put: :cancel_charging }

end
