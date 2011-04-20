require 'spec_helper'

describe RefundsController do

  context "with logged in user" do
    before :each do
      sign_in :user, authenticated_user
    end

    describe "GET :index" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :refundable).and_return(@mock_site = [mock_site])
      end

      context "user has at least one refundable site" do
        it "should render :index" do
          get :index
          response.should render_template(:index)
        end
      end
    end

    describe "POST :create" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :refundable, :find).with('1').and_return(
          @mock_site = mock_site(:id => 1, :hostname => 'rymai.com')
        )
      end

      context "site is refundable and already archived" do
        before(:each) do
          @mock_site.should_receive(:archived?) { true }
          @mock_site.should_receive(:refund)
        end

        it "should redirect to :index" do
          post :create, :site_id => '1'
          assigns(:site).should == @mock_site
          flash[:notice].should == I18n.t('site.refund.refunded', hostname: 'rymai.com')
          flash[:alert].should be_nil
          response.should redirect_to(refunds_url)
        end
      end

      context "site is refundable, not archived and archived is successful" do
        before(:each) do
          @mock_site.should_receive(:archived?) { false }
          @mock_site.should_receive(:without_password_validation) { true }
          @mock_site.should_receive(:refund)
        end

        it "should redirect to :index" do
          post :create, :site_id => '1'
          assigns(:site).should == @mock_site
          flash[:notice].should == I18n.t('site.refund.refunded', hostname: 'rymai.com')
          flash[:alert].should be_nil
          response.should redirect_to(refunds_url)
        end
      end

      context "site is refundable, not archived and archived is unsuccessful" do
        before(:each) do
          @mock_site.should_receive(:archived?) { false }
          @mock_site.should_receive(:without_password_validation) { false }
        end

        it "should redirect to :index" do
          post :create, :site_id => '1'
          assigns(:site).should == @mock_site
          flash[:notice].should be_nil
          flash[:alert].should == I18n.t('site.refund.refund_unsuccessful', hostname: 'rymai.com')
          response.should redirect_to(refunds_url)
        end
      end
    end
  end

  verb_and_actions = { :get => :index, :post => :create }
  it_should_behave_like "redirect when connected as", '/login', [:guest], verb_and_actions

end
