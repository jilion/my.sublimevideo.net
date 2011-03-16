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
      before(:each) { authenticated_user.should_receive(:cc?).and_return(true) }
      
      it "should redirect to /account/edit when authorization is ok without 3-d secure" do
        authenticated_user.should_receive(:attributes=).with({})
        authenticated_user.should_receive(:check_credit_card).and_return({ state: "authorized" })
        authenticated_user.should_receive(:save) { true }

        put :update, :user => {}
        response.should redirect_to(edit_user_registration_path)
      end

      it "should render HTML given by Aduno when authorization needs 3-d secure" do
        authenticated_user.should_receive(:attributes=).with({})
        authenticated_user.should_receive(:check_credit_card).and_return({ state: "d3d", message: "<html></html>" })

        put :update, :user => {}
        response.body.should == "<html></html>"
      end

      it "should render :edit template when user is not valid" do
        authenticated_user.should_receive(:attributes=).with({})
        authenticated_user.should_receive(:valid?) { false }
        authenticated_user.should_receive(:errors).at_least(1).times { { :base => "error" } }

        put :update, :user => {}
        response.should render_template(:edit)
      end

      it "should render :edit template when authorization is not ok" do
        authenticated_user.should_receive(:attributes=).with({})
        authenticated_user.should_receive(:valid?) { true }
        authenticated_user.should_receive(:check_credit_card) { nil }
        authenticated_user.should_receive(:errors).at_least(1).times { { :base => "error" } }

        put :update, :user => {}
        response.should render_template(:edit)
      end
    end
  end

  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :edit, :put => :update }

end
