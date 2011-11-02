require 'spec_helper'

describe TransactionsController do

  describe "#callback" do

    context "with a non-tempered request" do
      describe "credit card authorization response" do
        context "that succeeds" do
          before(:each) do
            @sha_params = {
              "PAYID" => "1234", "STATUS" => "5"
            }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=5"].join(Ogone.signature_out) + Ogone.signature_out).upcase
            }
            User.should_receive(:find).with(1).and_return(@m = mock_user(:i18n_notice_and_alert => nil))
          end

          it "should add a notice and redirect to /account/edit" do
            @m.should_receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            flash[:notice].should be_present
            flash[:alert].should be_nil
            response.should redirect_to(edit_user_registration_url)
          end
        end

        context "that's waiting" do
          before(:each) do
            @sha_params = {
              "PAYID" => "1234", "STATUS" => "51"
            }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=51"].join(Ogone.signature_out) + Ogone.signature_out).upcase
            }
            User.should_receive(:find).with(1).and_return(@m = mock_user(:i18n_notice_and_alert => { alert: I18n.t("credit_card.errors.waiting") }))
          end

          it "should add an alert and redirect to /account/edit" do
            @m.should_receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("credit_card.errors.waiting")
            response.should redirect_to(edit_user_registration_url)
          end
        end

        context "that fails (invalid)" do
          before(:each) do
            @sha_params = {
              "PAYID" => "1234", "STATUS" => "0"
            }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=0"].join(Ogone.signature_out) + Ogone.signature_out).upcase
            }
            User.should_receive(:find).with(1).and_return(@m = mock_user(:i18n_notice_and_alert => { alert: I18n.t("credit_card.errors.invalid") }))
          end

          it "should add an alert and redirect to /account/edit" do
            @m.should_receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("credit_card.errors.invalid")
            response.should redirect_to(edit_user_registration_url)
          end
        end

        context "that fails (refused)" do
          before(:each) do
            @sha_params = {
              "PAYID" => "1234", "STATUS" => "2"
            }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=2"].join(Ogone.signature_out) + Ogone.signature_out).upcase
            }
            User.should_receive(:find).with(1).and_return(@m = mock_user(:i18n_notice_and_alert => { alert: I18n.t("credit_card.errors.refused") }))
          end

          it "should add an alert and redirect to /account/edit" do
            @m.should_receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("credit_card.errors.refused")
            response.should redirect_to(edit_user_registration_url)
          end
        end

        context "that's unknown (status 52)" do
          before(:each) do
            @sha_params = {
              "PAYID" => "1234", "STATUS" => "52"
            }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=52"].join(Ogone.signature_out) + Ogone.signature_out).upcase
            }
            User.should_receive(:find).with(1).and_return(@m = mock_user(:i18n_notice_and_alert => { alert: I18n.t("credit_card.errors.unknown") }))
          end

          it "should add an alert and redirect to /account/edit" do
            @m.should_receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("credit_card.errors.unknown")
            response.should redirect_to(edit_user_registration_url)
          end
        end

        context "that's unknown (other status)" do
          before(:each) do
            @sha_params = {
              "PAYID" => "1234", "STATUS" => "187"
            }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=187"].join(Ogone.signature_out) + Ogone.signature_out).upcase
            }
            User.should_receive(:find).with(1).and_return(@m = mock_user(:i18n_notice_and_alert => { alert: I18n.t("credit_card.errors.unknown") }))
          end

          it "should add an alert and redirect to /account/edit" do
            @m.should_receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            flash[:notice].should == ""
            flash[:alert].should == I18n.t("credit_card.errors.unknown")
            response.should redirect_to(edit_user_registration_url)
          end
        end
      end

      describe "payment response" do
        before(:each) do
          @sha_params = {
            "PAYID" => "1234", "STATUS" => "9", "orderID" => "dwqdqw756w6q4d654qwd64qw"
          }
          @params = {
            "PAYMENT" => "TRUE",
            "SHASIGN" => Digest::SHA512.hexdigest(["ORDERID=dwqdqw756w6q4d654qwd64qw","PAYID=1234","STATUS=9"].join(Ogone.signature_out) + Ogone.signature_out).upcase
          }
        end

        context "transaction is already paid" do
          it "should return" do
            Transaction.should_receive(:find_by_order_id).with("dwqdqw756w6q4d654qwd64qw").and_return(mock_transaction(:paid? => true))
            mock_transaction.should_not_receive(:process_payment_response)

            post :callback, @params.merge(@sha_params)
            flash[:notice].should be_nil
            flash[:alert].should be_nil
            response.body.should be_blank
            response.status.should == 204
          end
        end

        context "transaction not already paid" do
          context "that succeeds" do
            before(:each) do
              @sha_params = {
                "PAYID" => "1234", "STATUS" => "9", "orderID" => "dwqdqw756w6q4d654qwd64qw"
              }
              @params = {
                "PAYMENT" => "TRUE",
                "SHASIGN" => Digest::SHA512.hexdigest(["ORDERID=dwqdqw756w6q4d654qwd64qw","PAYID=1234","STATUS=9"].join(Ogone.signature_out) + Ogone.signature_out).upcase
              }
            end

            it "should add a notice and redirect to /account/edit" do
              Transaction.should_receive(:find_by_order_id).with("dwqdqw756w6q4d654qwd64qw").and_return(@m = mock_transaction(:paid? => false, :state => 'paid'))
              @m.should_receive(:process_payment_response).with(@sha_params)

              post :callback, @params.merge(@sha_params)
              flash[:notice].should be_nil
              flash[:alert].should be_nil
              response.should redirect_to(sites_url)
            end
          end

          context "that fails" do
            before(:each) do
              @sha_params = {
                "PAYID" => "1234", "STATUS" => "2", "orderID" => "dwqdqw756w6q4d654qwd64qw"
              }
              @params = {
                "PAYMENT" => "TRUE",
                "SHASIGN" => Digest::SHA512.hexdigest(["ORDERID=dwqdqw756w6q4d654qwd64qw","PAYID=1234","STATUS=2"].join(Ogone.signature_out) + Ogone.signature_out).upcase
              }
            end

            it "should add an alert and redirect to /account/edit" do
              Transaction.should_receive(:find_by_order_id).with("dwqdqw756w6q4d654qwd64qw").and_return(@m = mock_transaction(:paid? => false, :state => 'failed'))
              @m.should_receive(:process_payment_response).with(@sha_params)

              post :callback, @params.merge(@sha_params)
              flash[:notice].should == ""
              flash[:alert].should == I18n.t("transaction.errors.failed")
              response.should redirect_to(sites_url)
            end
          end
        end
      end
    end

    context "with a tempered request" do
      before(:all) do
        @sha_params = {
          "PAYID" => "1234", "STATUS" => "5"
        }
        @params = {
          "CHECK_CC_USER_ID" => "1",
          "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=5"].join(Ogone.signature_out) + Ogone.signature_out).upcase
        }
        @sha_params["STATUS"] = "9" # tempering!!!!!
      end

      it "should void authorization" do
        post :callback, @params.merge(@sha_params)

        response.body.should be_blank
        response.status.should == 204
      end
    end

  end

end
