require 'spec_helper'

describe CreditCardsController do

  context "with a logged in user" do
    before(:each) { sign_in :user, authenticated_user }

    describe "GET edit" do
      context "with no credit card" do
        before(:each) do
          authenticated_user.should_receive(:cc?).and_return(false)
          authenticated_user.should_receive(:pending_cc?).and_return(false)
          authenticated_user.should_receive(:invoices_failed?).and_return(false)
          authenticated_user.should_receive(:invoices_open?).and_return(false)
        end

        it "should redirect to account/edit" do
          get :edit
          response.should redirect_to(edit_user_registration_path)
        end
      end

      context "with a pending credit card" do
        before(:each) do
          authenticated_user.should_receive(:cc?).and_return(false)
          authenticated_user.should_receive(:pending_cc?).and_return(true)
        end

        it "should render :edit template" do
          get :edit
          response.should render_template(:edit)
        end
      end

      context "with a failed invoices" do
        before(:each) do
          authenticated_user.should_receive(:cc?).and_return(false)
          authenticated_user.should_receive(:pending_cc?).and_return(false)
          authenticated_user.should_receive(:invoices_failed?).and_return(true)
        end

        it "should render :edit template" do
          get :edit
          response.should render_template(:edit)
        end
      end

      context "with a open invoices" do
        before(:each) do
          authenticated_user.should_receive(:cc?).and_return(false)
          authenticated_user.should_receive(:pending_cc?).and_return(false)
          authenticated_user.should_receive(:invoices_failed?).and_return(false)
          authenticated_user.should_receive(:invoices_open?).and_return(true)
        end

        it "should render :edit template" do
          get :edit
          response.should render_template(:edit)
        end
      end

      context "with a credit card" do
        before(:each) do
          authenticated_user.should_receive(:cc?).and_return(true)
        end

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
        authenticated_user.stub_chain(:credit_card, :valid?) { true }
        authenticated_user.should_receive(:check_credit_card)
      end

      context "with a valid site and 3d secure / authorized / waiting" do
        it "should render HTML given by Aduno when authorization needs 3-d secure" do
          authenticated_user.should_receive(:d3d_html).twice { "<form></form>" }

          put :update, :user => {}
          response.body.should == "<!DOCTYPE html><html><head><title>3DS Redirection</title></head><body><form></form></body></html>"
        end

        context "not 3d secure (yay!)" do
          before(:each) do
            authenticated_user.should_receive(:d3d_html) { nil }
          end

          it "should redirect to /account/edit when authorization is ok without 3-d secure" do
            authenticated_user.should_receive(:i18n_notice_and_alert) { nil }

            put :update, :user => {}
            flash[:notice].should be_present
            flash[:alert].should be_nil
            response.should redirect_to(edit_user_registration_path)
          end

          it "should redirect to /account/edit when authorization is waiting" do
            authenticated_user.should_receive(:i18n_notice_and_alert).twice { { notice: I18n.t("credit_card.errors.waiting") } }

            put :update, :user => {}
            flash[:notice].should == I18n.t("credit_card.errors.waiting")
            flash[:alert].should == ""
            response.should redirect_to(edit_user_registration_path)
          end

          it "should render :edit template when authorization is unknown" do
            authenticated_user.should_receive(:i18n_notice_and_alert).twice { { alert: I18n.t("credit_card.errors.unknown") } }

            put :update, :user => {}
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("credit_card.errors.unknown")
            response.should redirect_to(edit_user_registration_path)
          end
        end
      end

      context "with an invalid credit card" do
        before(:each) do
          authenticated_user.should_receive(:d3d_html) { nil }
        end

        it "should render :edit template when authorization is invalid" do
          authenticated_user.should_receive(:i18n_notice_and_alert).twice { { alert: I18n.t("credit_card.errors.invalid") } }

          put :update, :user => {}
          flash[:notice].should == ""
          flash[:alert].should == I18n.t("credit_card.errors.invalid")
          response.should redirect_to(edit_user_registration_path)
        end
      end

      context "with a refused credit card" do
        before(:each) do
          authenticated_user.should_receive(:d3d_html) { nil }
        end

        it "should render :edit template when authorization is invalid" do
          authenticated_user.should_receive(:i18n_notice_and_alert).twice { { alert: I18n.t("credit_card.errors.refused") } }

          put :update, :user => {}
          flash[:notice].should == ""
          flash[:alert].should == I18n.t("credit_card.errors.refused")
          response.should redirect_to(edit_user_registration_path)
        end
      end
    end
  end

  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :edit, :put => :update }

end
