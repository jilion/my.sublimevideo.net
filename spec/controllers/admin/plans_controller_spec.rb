require 'spec_helper'

describe Admin::PlansController do
  context "with logged in admin with the god role" do
    before { sign_in :admin, authenticated_admin(roles: ['god']) }

    describe "GET :index" do
      it "should render :index" do
        Plan.should_receive(:all).and_return([mock_plan])
        get :index
        assigns(:plans).should eq [mock_plan]
        response.should be_success
        response.should render_template(:index)
      end
    end

    describe "GET :new" do
      it "should render :index" do
        get :new
        response.should be_success
        response.should render_template(:new)
      end
    end

    describe "POST :create" do
      before { Plan.should_receive(:create_custom).with({}).and_return(mock_plan) }

      it "should redirect to /admin/plans when create succeeds" do
        post :create, plan: {}
        assigns(:plan).should eq mock_plan
        response.should redirect_to(admin_plans_url)
      end

      it "should render :new when fail" do
        mock_plan.should_receive(:errors).any_number_of_times.and_return(["error"])

        post :create, plan: {}
        assigns(:plan).should eq mock_plan
        response.should render_template(:new)
      end
    end

  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :new], post: :create }
  it_should_behave_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { get: [:index, :new], post: :create }

end
