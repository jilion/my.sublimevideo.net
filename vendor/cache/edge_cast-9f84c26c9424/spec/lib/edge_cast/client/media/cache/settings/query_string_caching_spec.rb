require 'spec_helper'

describe EdgeCast::Client::Media::Cache::Settings::QueryStringCaching do

  let(:client) { EdgeCast::Client.new }

  describe '.query_string_caching' do
    describe 'all query string caching settings' do
      context 'stubbed request' do
        before do
          client.should_receive(:get).with('querystringcaching') do
            [
              {
                "MediaTypeId" => 3,
                "QueryStringCaching" => "standard-cache"
              }, {
                "MediaTypeId" => 8,
                "QueryStringCaching" => "no-cache"
              }, {
                "MediaTypeId" => 14,
                "QueryStringCaching" => "unique-cache"
              }
            ]
          end
        end

        it 'returns the query string caching settings' do
          response = client.query_string_caching

          response.should be_an_instance_of(Hash)

          response[:http_large_object].should eq 'standard-cache'
          response[:hlo].should eq 'standard-cache'

          response[:http_small_object].should eq 'no-cache'
          response[:hso].should eq 'no-cache'

          response[:application_delivery_network].should eq 'unique-cache'
          response[:adn].should eq 'unique-cache'
        end
      end

      context 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the query string caching settings' do
          response = @client.query_string_caching
          response.should be_an_instance_of(Hash)
        end
      end
    end

    describe 'a specific query string caching setting' do
      context 'stubbed request' do
        before do
          client.should_receive(:get).with('querystringcaching?mediatypeid=3') do
            {
              "MediaTypeId" => 3,
              "QueryStringCaching" => "standard-cache"
            }
          end
        end

        it 'returns the query string caching setting' do
          response = client.query_string_caching(:http_large_object)

          response.should be_an_instance_of(Hash)

          response[:http_large_object].should eq 'standard-cache'
          response[:hlo].should eq 'standard-cache'
        end
      end

      context 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the query string caching setting' do
          response = @client.query_string_caching(:http_large_object)
          response.should be_an_instance_of(Hash)
        end
      end
    end
  end

  describe '.update_query_string_caching' do
    context 'stubbed request' do
      before do
        client.should_receive(:put).with('querystringcaching', { "MediaTypeId" => 3, "QueryStringCaching" => "no-cache" })
      end

      it 'returns the compression settings' do
        response = client.update_query_string_caching(:http_large_object, 'no-cache')

        response.should be_nil
      end
    end
  end

end
