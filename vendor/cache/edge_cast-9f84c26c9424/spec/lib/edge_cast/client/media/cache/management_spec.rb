require 'spec_helper'

describe EdgeCast::Client::Media::Cache::Management do

  let(:client) { EdgeCast::Client.new }

  describe '.load' do
    context 'stubbed rquest' do
      before do
        client.should_receive(:put).with('edge/load', { 'MediaPath' => 'http://cdn.example.org/dummy.js', 'MediaType' => 8 })
      end

      it 'loads the correct resource and returns nothing' do
        response = client.load(:http_small_object, 'http://cdn.example.org/dummy.js')
        response.should be_nil
      end      
    end

    context 'real request', :vcr, :if => ForReal.ok? do 
      it 'loads the correct resource and returns nothing' do
        response = @client.load(:http_small_object, ForReal.yml[:test_file_url])
        response.should be_nil
      end
    end
  end

  describe '.purge' do
    context 'stubbed rquest' do
      before do
        client.should_receive(:put).with('edge/purge', { 'MediaPath' => 'http://cdn.example.org/dummy.js', 'MediaType' => 8 })
      end
      
      it 'purges the correct resource and returns nothing' do
        response = client.purge(:http_small_object, 'http://cdn.example.org/dummy.js')
        response.should be_nil
      end
    end
    
    context 'real request', :vcr, :if => ForReal.ok? do 
      it 'purges the correct resource and returns nothing' do
        response = @client.purge(:http_small_object, ForReal.yml[:test_file_url])
        response.should be_nil
      end
    end
  end

end
