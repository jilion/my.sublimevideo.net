require 'spec_helper'

describe TransactionsController do

  describe "#ok" do
    
    context "with a non-tempered request" do
      
      describe "credit card authorization response" do
        before(:each) do
          @params_without_sha_out = {
            "PAYID" => "1234", "USER_ID" => "1", "CC_CHECK" => "TRUE", "STATUS" => "5"
          }
          @params = @params_without_sha_out.dup
          @params["SHASIGN"] = Digest::SHA512.hexdigest(@params.keys.sort { |a, b| a.upcase <=> b.upcase }.map { |s| "#{s.upcase}=#{@params[s]}" }.join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
        end
              
        context "with a succeeding cc authorization response" do
          it "should void authorization" do
            User.stub(:find).with(1).and_return(mock_user)
            mock_user.should_receive(:process_cc_authorization_response).with(@params_without_sha_out, "1234;RES") { nil }

            post :ok, @params
            flash[:notice].should be_present
            flash[:alert].should be_nil
          end
        end

        context "with a non-succeeding cc authorization response" do
          it "should void authorization" do
            User.stub(:find).with(1).and_return(mock_user)
            mock_user.should_receive(:process_cc_authorization_response).with(@params_without_sha_out, "1234;RES") { nil }
            mock_user.should_receive(:errors).at_least(1).times { { :base => "error" } }

            post :ok, @params
            flash[:notice].should be_nil
            flash[:alert].should be_present
          end
        end
      end
    end

    context "with a tempered request" do
      before(:each) do
        @params = {
          "PAYID" => "1234", "USER_ID" => "1", "CC_CHECK" => "TRUE", "STATUS" => "5"
        }
        @params["SHASIGN"] = Digest::SHA512.hexdigest(@params.keys.sort { |a, b| a.upcase <=> b.upcase }.map { |k,v| "#{k.upcase}=#{v}" }.join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]).upcase
        @params["USER_ID"] = "2" # tempering!!!!!
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
