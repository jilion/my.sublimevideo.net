require 'spec_helper'

describe TransactionsController do

  describe "#ok" do

    context "with a non-tempered request" do

      describe "credit card authorization response" do
        before(:all) do
          @params = {
            "PAYID" => "1234", "STATUS" => "5", "USER_ID" => "1", "CC_CHECK" => "TRUE",
            "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=5"].join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
          }
        end

        context "with a succeeding cc authorization response" do
          it "should void authorization" do
            User.should_receive(:find).with(1).and_return(mock_user)
            mock_user.should_receive(:process_cc_authorization_response).with(@params, "1234;RES") { nil }
            mock_user.should_receive(:save) { true }

            post :ok, @params
            flash[:notice].should be_present
            flash[:alert].should be_nil
            response.should redirect_to(edit_user_registration_url)
          end
        end

        context "with a non-succeeding cc authorization response" do
          it "should void authorization" do
            User.stub(:find).with(1).and_return(mock_user)
            mock_user.should_receive(:process_cc_authorization_response).with(@params, "1234;RES") { nil }
            mock_user.should_receive(:errors).at_least(1).times { { :base => "error" } }

            post :ok, @params
            flash[:notice].should be_nil
            flash[:alert].should be_present
          end
        end
      end
    end

    context "with a tempered request" do
      before(:all) do
        @params = {
          "PAYID" => "1234", "STATUS" => "5", "USER_ID" => "1", "CC_CHECK" => "TRUE",
          "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=5"].join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
        }
        @params["STATUS"] = "9" # tempering!!!!!
      end

      it "should void authorization" do
        post :ok, @params

        response.body.should == "Tampered request!"
        response.status.should == 400
      end
    end

  end

  describe "#ko" do

  end

end
