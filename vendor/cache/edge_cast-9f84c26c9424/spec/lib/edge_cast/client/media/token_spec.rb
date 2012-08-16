require 'spec_helper'

describe EdgeCast::Client::Media::Token do

  let(:client) { EdgeCast::Client.new }

  describe '.encrypt_token_data' do
    describe 'all log format settings' do
      context 'stubbed request' do
        before do
          client.should_receive(:put).with('token/encrypt', {
            'Key' => 'abcd1234',
            'TokenParameter' => 'ec_expire=1356955200&ec_country_deny=CA&ec_country_allow=US,MX'
          }).and_return({ :token => 'foobar' })
        end

        it 'returns the log storage settings' do
          response = client.encrypt_token_data(:key => 'abcd1234', :token_parameter => 'ec_expire=1356955200&ec_country_deny=CA&ec_country_allow=US,MX')

          response.should == { :token => 'foobar' }
        end
      end

      pending 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the log format settings' do
          response = @client.encrypt_token_data(:key => 'abcd1234', :token_parameter => 'ec_expire=1356955200&ec_country_deny=CA&ec_country_allow=US,MX')

          response.should be_nil
        end
      end
    end
  end

end
