require 'spec_helper'

describe TransactionsController do

  describe "#callback" do

    context "with a non-tempered request" do
      describe "credit card authorization response" do
        before(:each) do
          @sha_params = {
            "PAYID" => "1234", "STATUS" => "5"
          }
          @params = {
            "USER_ID" => "1", "CC_CHECK" => "TRUE",
            "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=5"].join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
          }
        end
        before(:each) { User.stub(:find).with(1).and_return(mock_user) }

        context "that succeeds" do
          it "should add a notice and redirect to /account/edit" do
            mock_user.should_receive(:process_cc_authorization_response).with(@sha_params, "1234;RES").and_return("authorized")
            mock_user.should_receive(:save) { true }

            post :callback, @params.merge(@sha_params)
            flash[:notice].should be_present
            flash[:alert].should be_nil
            response.should redirect_to(edit_user_registration_url)
          end
        end

        context "that fails" do
          it "should add an alert and redirect to /account/edit" do
            mock_user.should_receive(:process_cc_authorization_response).with(@sha_params, "1234;RES").and_return("refused")

            post :callback, @params.merge(@sha_params)
            flash[:notice].should be_nil
            flash[:alert].should be_present
            response.should redirect_to(edit_user_registration_url)
          end
        end
      end

      describe "payment response" do
        before(:each) do
          @sha_params = {
            "PAYID" => "1234", "STATUS" => "5", "ORDERID" => "2"
          }
          @params = {
            "PAYMENT" => "TRUE", "ACTION" => "create",
            "SHASIGN" => Digest::SHA512.hexdigest(["ORDERID=2","PAYID=1234","STATUS=5"].join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
          }
        end
        before(:each) do
          Transaction.should_receive(:find_by_id).with(2).and_return(mock_transaction)
        end

        context "transaction is already paid" do
          it "should return" do
            mock_transaction.should_receive(:paid?) { true }
            mock_transaction.should_not_receive(:process_payment_response)

            post :callback, @params.merge(@sha_params)
            flash[:notice].should be_nil
            flash[:alert].should be_nil
            response.body.should be_blank
            response.status.should == 204
          end
        end

        context "transaction not already paid" do
          before(:each) do
            mock_transaction.should_receive(:process_payment_response).with(@sha_params)
          end

          context "that succeeds" do
            it "should add a notice and redirect to /account/edit" do
              mock_transaction.should_receive(:paid?).ordered { false }
              mock_transaction.should_receive(:paid?).ordered { true }

              post :callback, @params.merge(@sha_params)
              flash[:notice].should be_present
              flash[:alert].should be_nil
              response.should redirect_to(sites_url)
            end
          end

          context "that fails" do
            it "should add an alert and redirect to /account/edit" do
              mock_transaction.should_receive(:paid?).twice { false }
              mock_transaction.should_receive(:failed?)     { true }
              mock_transaction.should_receive(:error_key)   { "refused" }

              post :callback, @params.merge(@sha_params)
              flash[:notice].should be_nil
              flash[:alert].should be_present
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
          "USER_ID" => "1", "CC_CHECK" => "TRUE",
          "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=5"].join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
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
