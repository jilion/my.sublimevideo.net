require 'spec_helper'

describe TransactionsController do

  describe "#callback" do

    context "with a non-tempered request" do

      describe "credit card authorization response" do
        before(:all) do
          @sha_params = {
            "PAYID" => "1234", "STATUS" => "5"
          }
          @params = {
            "USER_ID" => "1", "CC_CHECK" => "TRUE",
            "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=5"].join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
          }
        end

        context "with a succeeding cc authorization response" do
          it "should void authorization" do
            User.should_receive(:find).with(1).and_return(mock_user)
            mock_user.should_receive(:process_cc_authorization_response).with(@sha_params, "1234;RES").and_return({ state: "authorized" })
            mock_user.should_receive(:save) { true }

            post :callback, @params.merge(@sha_params)
            flash[:notice].should be_present
            flash[:alert].should be_nil
            response.should redirect_to(edit_user_registration_url)
          end
        end

        context "with a non-succeeding cc authorization response" do
          it "should void authorization" do
            User.stub(:find).with(1).and_return(mock_user)
            mock_user.should_receive(:process_cc_authorization_response).with(@sha_params, "1234;RES").and_return({ state: "refused", message: "Foo bar" })

            post :callback, @params.merge(@sha_params)
            flash[:notice].should be_nil
            flash[:alert].should == "Foo bar"
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

        response.body.should == "Tampered request!"
        response.status.should == 400
      end
    end

  end

end
