require 'spec_helper'

describe TransactionsController do

  describe "#payment_ok" do
    context "with a non-tempered request" do

      context "with a succeeding cc authorization response" do
        before(:each) do
          @params_without_sha_out = {
            "PAYID" => "1234", "USER_ID" => "1", "CC_CHECK" => "TRUE", "STATUS" => "5"
          }
          @params = @params_without_sha_out.dup
          @params["SHASIGN"] = Digest::SHA512.hexdigest(@params.keys.sort { |a, b| a.upcase <=> b.upcase }.map { |s| "#{s.upcase}=#{@params[s]}" }.join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
        end

        it "should void authorization" do
          User.stub(:find).with(1).and_return(mock_user)
          mock_user.should_receive(:process_cc_authorization_response).with(@params_without_sha_out, "1234;RES") { nil }
          # mock_user.should_receive(:void_authorization).with("1234;RES") { true }

          post :payment_ok, @params
        end
      end

    end
  end

  describe "#payment_ko" do

  end
  
end
