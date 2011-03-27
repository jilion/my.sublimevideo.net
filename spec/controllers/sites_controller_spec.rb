require 'spec_helper'

describe SitesController do

  context "with logged in user" do
    before :each do
      sign_in :user, authenticated_user
    end

    describe "GET :index" do
      context "user has no non-archived sites" do
        it "should redirect to /sites/new" do
          authenticated_user.stub_chain(:sites, :not_archived, :includes, :by_date).and_return([])

          get :index
          response.should redirect_to(new_site_path)
        end
      end
      
      context "user has at least one non-archived site" do
        it "should render :index" do
          authenticated_user.stub_chain(:sites, :not_archived, :includes, :by_date).and_return(@mock_sites = [mock_site])

          get :index
          assigns(:sites).should == @mock_sites
          response.should render_template(:index)
        end
      end
    end

    describe "GET :code" do
      it "should render :code" do
        authenticated_user.stub_chain(:sites, :find_by_token!).with('a1b2c3').and_return(@mock_site = mock_site)

        get :code, :id => 'a1b2c3', :format => :js
        assigns(:site).should == @mock_site
        response.should render_template(:code)
      end
    end

    describe "GET :new" do
      it "should render :new" do
        authenticated_user.stub_chain(:sites, :build).and_return(@mock_site = mock_site)

        get :new
        assigns(:site).should == @mock_site
        response.should render_template(:new)
      end
    end

    describe "GET :edit" do
      it "should render :edit" do
        authenticated_user.stub_chain(:sites, :find_by_token!).with('a1b2c3').and_return(@mock_site = mock_site)

        get :edit, :id => 'a1b2c3'
        assigns(:site).should == @mock_site
        response.should render_template(:edit)
      end
    end

    describe "GET :state" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :find).with('1') { @mock_site }
      end
      
      it "should respond with :ok when cdn_up_to_date? is false" do
        get :state, :id => '1', :format => :js
        assigns(:site).should == @mock_site
        response.should be_success
      end

      it "should render :state when cdn_up_to_date? is true" do
        get :state, :id => '1', :format => :js
        assigns(:site).should == @mock_site
        response.should render_template(:state)
      end
    end

    describe "POST :create" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :build).with({}).and_return(@mock_site = mock_site)
        mock_user.should_receive(:credit_card)
        @mock_site.should_receive(:charging_options=)
      end

      context "with a valid site" do

        describe "dev plan" do
          before(:each) do
            @mock_site.should_receive(:user).and_return(mock_user)
            @mock_site.should_receive(:in_or_will_be_in_paid_plan?).twice { false }
            @mock_site.should_receive(:save) { true }
          end

          it "should redirect to /sites" do
            post :create, :site => {}
            assigns(:site).should == @mock_site
            flash[:notice].should be_present
            response.should redirect_to(sites_url)
          end
        end

        describe "paid plan" do
          before(:each) do
            @mock_site.should_receive(:save) { true }
            @mock_site.should_receive(:in_or_will_be_in_paid_plan?).twice { true }
            @mock_site.should_receive(:will_be_in_dev_plan?) { false }
            @mock_site.should_receive(:user).twice.and_return(mock_user)
            mock_user.should_receive(:attributes=)
            @mock_site.stub_chain(:last_invoice, :last_transaction).and_return(@mock_transaction = mock_transaction)
          end

          it "should render HTML given by Aduno when authorization needs 3-d secure" do
            @mock_transaction.should_receive(:error)        { "<html></html>" }
            @mock_transaction.should_receive(:waiting_d3d?) { true }

            post :create, :site => {}
            assigns(:site).should == @mock_site
            response.body.should == "<html></html>"
          end

          it "should render :edit template when payment is invalid" do
            @mock_transaction.should_receive(:waiting_d3d?)   { false }
            @mock_transaction.should_receive(:failed?)        { true }
            @mock_transaction.should_receive(:i18n_error_key) { "invalid" }

            post :create, :site => {}
            assigns(:site).should == @mock_site
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("transaction.errors.invalid")
            response.should redirect_to(sites_url)
          end

          it "should render :edit template when payment is refused" do
            @mock_transaction.should_receive(:waiting_d3d?)   { false }
            @mock_transaction.should_receive(:failed?)        { true }
            @mock_transaction.should_receive(:i18n_error_key) { "refused" }

            post :create, :site => {}
            assigns(:site).should == @mock_site
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("transaction.errors.refused")
            response.should redirect_to(sites_url)
          end

          it "should redirect to /sites when payment is ok without 3-d secure" do
            @mock_transaction.should_receive(:waiting_d3d?) { false }
            @mock_transaction.should_receive(:failed?)      { false }
            @mock_transaction.should_receive(:unprocessed?) { false }

            post :create, :site => {}
            assigns(:site).should == @mock_site
            flash[:notice].should be_present
            response.should redirect_to(sites_url)
          end

          it "should redirect to /sites when payment is ok without 3-d secure" do
            @mock_transaction.should_receive(:waiting_d3d?)   { false }
            @mock_transaction.should_receive(:failed?)        { false }
            @mock_transaction.should_receive(:unprocessed?)   { true }
            @mock_transaction.should_receive(:i18n_error_key) { "unknown" }

            post :create, :site => {}
            assigns(:site).should == @mock_site
            flash[:notice].should == I18n.t("transaction.errors.unknown")
            response.should redirect_to(sites_url)
          end
        end

      end

      context "with an invalid site" do

        describe "dev plan" do
          before(:each) do
            @mock_site.should_receive(:user).and_return(mock_user)
            @mock_site.should_receive(:in_or_will_be_in_paid_plan?) { false }
            @mock_site.should_receive(:save) { false }
          end

          it "should redirect to /sites" do
            post :create, :site => {}
            assigns(:site).should == @mock_site
            response.should render_template(:new)
          end
        end
        
        describe "paid plan" do
          before(:each) do
            @mock_site.should_receive(:in_or_will_be_in_paid_plan?) { true }
            @mock_site.should_receive(:will_be_in_dev_plan?) { false }
            @mock_site.should_receive(:save) { false }
            @mock_site.should_receive(:user).twice.and_return(mock_user)
            mock_user.should_receive(:attributes=)
          end

          it "should redirect to /sites" do
            post :create, :site => {}
            assigns(:site).should == @mock_site
            response.should render_template(:new)
          end
        end

      end
    end

    describe "DELETE :destroy" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :find_by_token!).with('a1b2c3').and_return(@mock_site = mock_site)
      end
      
      it "should redirect to /sites if password is sent" do
        @mock_site.should_receive(:user_attributes=).with("current_password" => '123456')
        @mock_site.should_receive(:archive).and_return(true)

        delete :destroy, :id => 'a1b2c3', :site => { :user_attributes => { :current_password => '123456' } }
        assigns(:site).should == @mock_site
        response.should redirect_to(sites_url)
      end

      it "should render '/sites/:token/edit' without password" do
        @mock_site.should_receive(:user_attributes=).with(nil)
        @mock_site.should_receive(:archive).and_return(false)

        delete :destroy, :id => 'a1b2c3'
        assigns(:site).should == @mock_site
        response.should render_template('sites/edit')
      end
    end
  end

  verb_and_actions = { :get => [:index, :code, :new, :edit, :state], :post => :create, :put => :update, :delete => :destroy }
  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], verb_and_actions
  it_should_behave_like "redirect when connected as", '/login', [:guest], verb_and_actions

end