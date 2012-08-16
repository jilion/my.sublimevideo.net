require "spec_helper"

describe EdgeCast::Connection do

  before do
    @client = EdgeCast::Client.new(:account_number => 'abc123')
  end

  describe '.endpoint' do  
    it 'returns the default endpoint' do
      @client.endpoint.should eq "https://#{EdgeCast::Config::DEFAULT_HOST}/v2/mcc/customers/abc123"
    end
  end

end
