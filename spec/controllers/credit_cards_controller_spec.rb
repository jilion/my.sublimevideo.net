require 'spec_helper'

describe CreditCardsController do

  context "with a logged in user" do
    before(:each) { sign_in :user, authenticated_user }

    describe "GET edit" do
      context "with no credit card" do
        before(:each) { authenticated_user.should_receive(:cc?).and_return(false) }

        it "should redirect to account/edit" do
          get :edit
          response.should redirect_to(edit_user_registration_path)
        end
      end

      context "with a credit card" do
        before(:each) { authenticated_user.should_receive(:cc?).and_return(true) }

        it "should render :edit template" do
          get :edit
          response.should render_template(:edit)
        end
      end
    end

    describe "PUT update" do
      before(:each) do
        authenticated_user.should_receive(:cc?).and_return(true)
        authenticated_user.should_receive(:attributes=).with({})
      end

      context "with a valid site" do
        it "should render HTML given by Aduno when authorization needs 3-d secure" do
          authenticated_user.should_receive(:check_credit_card).and_return("d3d")
          authenticated_user.should_receive(:d3d_html) { "<html></html>" }

          put :update, :user => {}
          response.body.should == "<html></html>"
        end

        it "should render :edit template when authorization is invalid" do
          authenticated_user.should_receive(:check_credit_card) { "invalid" }
          authenticated_user.should_receive(:errors).at_least(1).times { { :base => "error" } }

          put :update, :user => {}
          flash[:alert].should be_nil
          response.should render_template(:edit)
        end

        it "should render :edit template when authorization is refused" do
          authenticated_user.should_receive(:check_credit_card) { "refused" }
          authenticated_user.should_receive(:errors).at_least(1).times { { :base => "error" } }

          put :update, :user => {}
          flash[:alert].should be_nil
          response.should render_template(:edit)
        end

        it "should redirect to /account/edit when authorization is waiting" do
          authenticated_user.should_receive(:check_credit_card) { "waiting" }

          put :update, :user => {}
          flash[:notice].should be_present
          response.should redirect_to(edit_user_registration_path)
        end

        it "should redirect to /account/edit when authorization is ok without 3-d secure" do
          authenticated_user.should_receive(:check_credit_card).and_return("authorized")

          put :update, :user => {}
          flash[:notice].should be_present
          response.should redirect_to(edit_user_registration_path)
        end
      end

      context "with a valid site" do
        it "should render :edit template when user is not valid" do
          authenticated_user.should_receive(:check_credit_card).and_return(nil)

          put :update, :user => {}
          response.should render_template(:edit)
        end
      end

    end
  end

  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :edit, :put => :update }

end
