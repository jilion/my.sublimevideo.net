require 'spec_helper'

describe PlansController do

  context "with logged in user" do
    before :each do
      sign_in :user, authenticated_user
    end

    describe "GET :edit" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :find_by_token!).with('a1b2c3').and_return(mock_site)
      end

      it "should render :edit" do
        get :edit, :site_id => 'a1b2c3'
        assigns(:site).should == mock_site
        response.should render_template(:edit)
      end
    end

    describe "PUT :update" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :find_by_token!).with('a1b2c3').and_return(mock_site)
        mock_site.should_receive(:user) { mock_user }
        mock_user.should_receive(:attributes=)
        mock_site.should_receive(:attributes=)
        mock_user.should_receive(:credit_card)
        mock_site.should_receive(:charging_options=)
        mock_site.should_receive(:user).and_return(mock_user)
      end

      context "with a valid site" do
        before(:each) do
          mock_site.should_receive(:save) { true }
        end

        describe "dev plan" do
          it "should redirect to /sites" do
            mock_site.should_receive(:transaction).twice.and_return(nil)

            put :update, :site_id => 'a1b2c3', :site => {}
            assigns(:site).should == mock_site
            flash[:notice].should == I18n.t("flash.plans.update.notice")
            flash[:alert].should be_nil
            response.should redirect_to(sites_url)
          end
        end

        describe "paid plan" do
          it "should render HTML given by Aduno when authorization needs 3-d secure" do
            mock_site.should_receive(:transaction).twice.and_return(mock_transaction(:waiting_d3d? => true, :error => "<form></form>"))

            put :update, :site_id => 'a1b2c3', :site => {}
            assigns(:site).should == mock_site
            response.body.should == "<!DOCTYPE html><html><head><title>3DS Redirection</title></head><body><form></form></body></html>"
          end

          it "should render :edit template when payment is failed" do
            mock_site.should_receive(:transaction).twice.and_return(mock_transaction(:waiting_d3d? => false, :state => "failed"))

            put :update, :site_id => 'a1b2c3', :site => {}
            assigns(:site).should == mock_site
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("transaction.errors.failed")
            response.should redirect_to(sites_url)
          end

          it "should redirect to /sites when payment is ok without 3-d secure" do
            mock_site.should_receive(:transaction).twice.and_return(mock_transaction(:waiting_d3d? => false, :state => "paid"))

            put :update, :site_id => 'a1b2c3', :site => {}
            assigns(:site).should == mock_site
            flash[:notice].should == I18n.t("flash.plans.update.notice")
            flash[:alert].should be_nil
            response.should redirect_to(sites_url)
          end

          it "should redirect to /sites when payment is waiting" do
            mock_site.should_receive(:transaction).twice.and_return(mock_transaction(:waiting_d3d? => false, :state => "waiting"))

            put :update, :site_id => 'a1b2c3', :site => {}
            assigns(:site).should == mock_site
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("transaction.errors.waiting")
            response.should redirect_to(sites_url)
          end
        end
      end

      context "with an invalid site" do
        before(:each) do
          mock_site.should_receive(:save) { false }
        end

        it "should render :edit template" do
          put :update, :site_id => 'a1b2c3', :site => {}
          assigns(:site).should == mock_site
          flash[:notice].should == ""
          flash[:alert].should == ""
          response.should render_template(:edit)
        end
      end
    end

    describe "DELETE :destroy" do
      before(:each) do
        authenticated_user.stub_chain(:sites, :find_by_token!).with('a1b2c3').and_return(mock_site)
      end

      it "should redirect to /sites when update_attributes succeeds" do
        mock_site.stub(:update_attribute).with(:next_cycle_plan_id, nil) { true }

        delete :destroy, :site_id => 'a1b2c3'
        assigns(:site).should == mock_site
        response.should redirect_to sites_path
      end
    end
  end

  verb_and_actions = { :get => :edit, :put => :update }
  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { :suspended? => true }]], verb_and_actions, :site_id => "1"
  it_should_behave_like "redirect when connected as", '/login', [:guest], verb_and_actions, :site_id => "1"

end
