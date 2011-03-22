require 'spec_helper'

describe SitesController do

  context "with logged in user" do
    before :each do
      sign_in :user, authenticated_user
      authenticated_user.stub_chain(:sites, :find_by_token).with('a1b2c3') { @mock_site = mock_site }
      authenticated_user.stub_chain(:sites, :find).with('1') { @mock_site }
    end

    describe "GET :index" do
      before :each do
        authenticated_user.stub_chain(:sites, :not_archived, :includes, :by_date).and_return([mock_site])
        get :index
      end

      it "should assign sites array as @sites" do
        assigns(:sites).should == [mock_site]
      end

      it "should render :index" do
        response.should render_template(:index)
      end
    end

    describe "GET :code" do
      it "should render :code" do
        get :code, :id => 'a1b2c3', :format => :js
        assigns(:site).should == mock_site
        response.should render_template(:code)
      end
    end

    describe "GET :new" do
      it "should render :new" do
        authenticated_user.stub_chain(:sites, :build) { mock_site }

        get :new
        response.should render_template(:new)
      end
    end

    describe "GET :edit" do
      it "should render :edit" do
        get :edit, :id => 'a1b2c3'
        assigns(:site).should == mock_site
        response.should render_template(:edit)
      end
    end

    describe "GET :state" do
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
        @mock_site.should_receive(:d3d_options=) { hash_including(:action => "create") }
        @mock_site.should_receive(:user).and_return(mock_user)
      end

      context "with a valid site" do
        before(:each) do
          @mock_site.should_receive(:save) { true }
          @mock_site.stub_chain(:last_invoice, :transaction).and_return(@mock_transaction = mock_transaction(error_code: "refused"))
        end

        it "should render HTML given by Aduno when authorization needs 3-d secure" do
          @mock_transaction.should_receive(:d3d_html) { "<html></html>" }
          @mock_transaction.should_receive(:waiting_d3d?) { true }

          post :create, :site => {}
          response.body.should == "<html></html>"
        end

        it "should render :edit template when payment is failed" do
          @mock_transaction.should_receive(:waiting_d3d?) { false }
          @mock_transaction.should_receive(:failed?)      { true }

          post :create, :site => {}
          flash[:alert].should be_present
          response.should redirect_to(edit_site_plan_url(@mock_site))
        end

        it "should redirect to /sites when payment is ok without 3-d secure" do
          @mock_transaction.should_receive(:waiting_d3d?)   { false }
          @mock_transaction.should_receive(:failed?)        { false }
          @mock_transaction.should_receive(:succeed?).twice { true }

          post :create, :site => {}
          flash[:notice].should be_present
          response.should redirect_to(sites_url)
        end
      end

      context "with an invalid site" do
        before(:each) do
          @mock_site.should_receive(:save) { false }
        end

        it "should render :edit template when user is not valid" do
          post :create, :site => {}
          response.should render_template(:edit)
        end
      end
    end

    describe "PUT :update" do
      it "should redirect to /sites when update_attributes succeeds" do
        mock_site.stub(:update_attributes).with({}) { true }

        put :update, :id => 'a1b2c3', :site => {}, :user => { :current_password => '123456' }
        assigns(:site).should == mock_site
        response.should redirect_to(sites_url)
      end

      it "should redirect to /sites/:token/edit when update_attributes fails" do
        mock_site.stub(:update_attributes).with({}) { false }
        mock_site.should_receive(:errors).any_number_of_times.and_return(["error"])

        put :update, :id => 'a1b2c3', :site => {}, :user => { :current_password => '123456' }
        assigns(:site).should == mock_site
        response.should render_template(:edit)
      end
    end

    describe "DELETE :destroy" do
      it "should redirect to /sites if password is sent" do
        mock_site.should_receive(:user_attributes=).with("current_password" => '123456')
        mock_site.should_receive(:archive).and_return(true)

        delete :destroy, :id => 'a1b2c3', :site => { :user_attributes => { :current_password => '123456' } }
        assigns(:site).should == mock_site
        response.should redirect_to(sites_url)
      end

      it "should render '/sites/:token/edit' without password" do
        mock_site.should_receive(:user_attributes=).with(nil)
        mock_site.should_receive(:archive).and_return(false)

        delete :destroy, :id => 'a1b2c3'
        assigns(:site).should == mock_site
        response.should render_template('sites/edit')
      end
    end
  end

  verb_and_actions = { :get => [:index, :code, :new, :edit, :state], :post => :create, :put => :update, :delete => :destroy }
  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], verb_and_actions
  it_should_behave_like "redirect when connected as", '/login', [:guest], verb_and_actions

end