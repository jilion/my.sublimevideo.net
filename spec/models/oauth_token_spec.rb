require 'spec_helper'

describe RequestToken do

  before(:each) do
    @token = Factory(:request_token)
    @user  = Factory(:user)
  end

  it "should be valid" do
    @token.should be_valid
  end

  it "should not have errors" do
    @token.errors.should be_empty
  end

  it "should have a token" do
    @token.token.should_not be_nil
  end

  it "should have a secret" do
    @token.secret.should_not be_nil
  end

  it "should not be authorized" do
    @token.should_not be_authorized
  end

  it "should not be invalidated" do
    @token.should_not be_invalidated
  end

  it "should not have a verifier" do
    @token.verifier.should be_nil
  end

  it "should not be oob" do
    @token.should_not be_oob
  end

  describe "OAuth 1.0a" do

    describe "with provided callback" do
      before(:each) do
        @token.callback_url = "http://test.com/callback"
      end

      it "should not be oauth10" do
        @token.should_not be_oauth10
      end

      it "should not be oob" do
        @token.should_not be_oob
      end

      describe "authorize request" do
        before(:each) do
          @token.authorize!(@user)
        end

        it "should be authorized" do
          @token.should be_authorized
        end

        it "should have authorized at" do
          @token.authorized_at.should_not be_nil
        end

        it "should have user set" do
          @token.user.should eql @user
        end

        it "should have verifier" do
          @token.verifier.should_not be_nil
        end

        describe "exchange for access token" do

          before(:each) do
            @token.provided_oauth_verifier = @token.verifier
            @access = @token.exchange!
          end

          it "should be valid" do
            @access.should be_valid
          end

          it "should have no error messages" do
            @access.errors.full_messages.should be_empty
          end

          it "should invalidate request token" do
            @token.should be_invalidated
          end

          it "should set user on access token" do
            @access.user.should eql @user
          end

          it "should authorize accesstoken" do
            @access.should be_authorized
          end
        end

        describe "attempt exchange with invalid verifier (OAuth 1.0a)" do

          before(:each) do
            @value = @token.exchange!
          end

          it "should return false" do
            @value.should be_false
          end

          it "should not invalidate request token" do
            @token.should_not be_invalidated
          end
        end

      end

      describe "attempt exchange with out authorization" do

        before(:each) do
          @value = @token.exchange!
        end

        it "should return false" do
          @value.should be_false
        end

        it "should not invalidate request token" do
          @token.should_not be_invalidated
        end
      end

      it "should return 1.0a style to_query" do
        @token.to_query.should eql "oauth_token=#{@token.token}&oauth_token_secret=#{@token.secret}&oauth_callback_confirmed=true"
      end

    end

    describe "with oob callback" do
      before(:each) do
        @token.callback_url = 'oob'
      end

      it "should not be oauth10" do
        @token.should_not be_oauth10
      end

      it "should be oob" do
        @token.should be_oob
      end

      describe "authorize request" do
        before(:each) do
          @token.authorize!(@user)
        end

        it "should be authorized" do
          @token.should be_authorized
        end

        it "should have authorized at" do
          @token.authorized_at.should_not be_nil
        end

        it "should have user set" do
          @token.user.should eql @user
        end

        it "should have verifier" do
          @token.verifier.should_not be_nil
        end

        describe "exchange for access token" do

          before(:each) do
            @token.provided_oauth_verifier = @token.verifier
            @access = @token.exchange!
          end

          it "should invalidate request token" do
            @token.should be_invalidated
          end

          it "should set user on access token" do
            @access.user.should eql @user
          end

          it "should authorize accesstoken" do
            @access.should be_authorized
          end
        end

        describe "attempt exchange with invalid verifier (OAuth 1.0a)" do

          before(:each) do
            @value = @token.exchange!
          end

          it "should return false" do
            @value.should be_false
          end

          it "should not invalidate request token" do
            @token.should_not be_invalidated
          end
        end

      end

      describe "attempt exchange with out authorization invalid verifier" do

        before(:each) do
          @value = @token.exchange!
        end

        it "should return false" do
          @value.should be_false
        end

        it "should not invalidate request token" do
          @token.should_not be_invalidated
        end
      end

      it "should return 1.0 style to_query" do
        @token.to_query.should eql "oauth_token=#{@token.token}&oauth_token_secret=#{@token.secret}&oauth_callback_confirmed=true"
      end
    end
  end

  if defined? OAUTH_10_SUPPORT && OAUTH_10_SUPPORT
    describe "OAuth 1.0" do
  
      it "should be oauth10" do
        @token.should be_oauth10
      end
  
      it "should not be oob" do
        @token.should_not be_oob
      end
  
      describe "authorize request" do
        before(:each) do
          @token.authorize!(@user)
        end
  
        it "should be authorized" do
          @token.should be_authorized
        end
  
        it "should have authorized at" do
          @token.authorized_at.should_not be_nil
        end
  
        it "should have user set" do
          @token.user.should eql @user
        end
  
        it "should not have verifier" do
          @token.verifier.should be_nil
        end
  
        describe "exchange for access token" do
  
          before(:each) do
            @access = @token.exchange!
          end
  
          it "should invalidate request token" do
            @token.should be_invalidated
          end
  
          it "should set user on access token" do
            @access.user.should eql @user
          end
  
          it "should authorize accesstoken" do
            @access.should be_authorized
          end
        end
  
      end
  
      describe "attempt exchange with out authorization" do
  
        before(:each) do
          @value = @token.exchange!
        end
  
        it "should return false" do
          @value.should be_false
        end
  
        it "should not invalidate request token" do
          @token.should_not be_invalidated
        end
      end
  
      it "should return 1.0 style to_query" do
        @token.to_query.should eql "oauth_token=#{@token.token}&oauth_token_secret=#{@token.secret}"
      end
  
    end
  end
end

# == Schema Information
#
# Table name: oauth_tokens
#
#  id                    :integer         not null, primary key
#  user_id               :integer
#  type                  :string(20)
#  client_application_id :integer
#  token                 :string(40)
#  secret                :string(40)
#  callback_url          :string(255)
#  verifier              :string(20)
#  scope                 :string(255)
#  authorized_at         :datetime
#  invalidated_at        :datetime
#  valid_to              :datetime
#  created_at            :datetime
#  updated_at            :datetime
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

