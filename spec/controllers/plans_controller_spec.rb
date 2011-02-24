require 'spec_helper'

describe PlansController do

  context "with logged in user" do
    before :each do
      sign_in :user, authenticated_user
      @current_user.stub_chain(:sites, :find_by_token).with('a1b2c3') { mock_site }
    end

    describe "GET :edit" do
      it "should render :edit" do
        get :edit, :site_id => 'a1b2c3'
        assigns(:site).should == @mock_site
        response.should render_template(:edit)
      end
    end

    describe "PUT :update" do
      context "with wrong password" do
        before(:each) { @current_user.stub(:valid_password?).with('abcd').and_return(false) }

        it "should redirect to /sites/:token/edit" do
          put :update, :site_id => 'a1b2c3', :site => {}, :user => { :current_password => 'abcd' }
          assigns(:site).should == mock_site
          response.should redirect_to(edit_site_plan_url(mock_site))
        end
      end

      context "with good password" do
        before(:each) do
          @current_user.stub(:valid_password?).with('123456').and_return(true)
        end

        it "should redirect to /sites when update_attributes succeeds" do
          mock_site.stub(:update_attributes).with({}) { true }

          put :update, :site_id => 'a1b2c3', :site => {}, :user => { :current_password => '123456' }
          assigns(:site).should == mock_site
          response.should redirect_to(sites_url)
        end

        it "should redirect to /sites/:token/plan/edit when update_attributes fails" do
          mock_site.stub(:update_attributes).with({}) { false }
          mock_site.should_receive(:errors).any_number_of_times.and_return(["error"])

          put :update, :site_id => 'a1b2c3', :site => {}, :user => { :current_password => '123456' }
          assigns(:site).should == mock_site
          response.should render_template("plans/edit")
        end
      end
    end
  end

  verb_and_actions = { :get => :edit, :put => :update }
  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], verb_and_actions, :site_id => "1"
  it_should_behave_like "redirect when connected as", '/login', [:guest], verb_and_actions, :site_id => "1"

end
