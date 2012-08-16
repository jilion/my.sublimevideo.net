require 'spec_helper'

describe EdgeCast::Client::Media::Cache::Settings::QueryStringLogging do

  let(:client) { EdgeCast::Client.new }

  describe '.query_string_logging' do
    describe 'all query string logging settings' do
      context 'stubbed request' do
        before do
          client.should_receive(:get).with('querystringlogging') do
            [
              {
                "MediaTypeId" => 3,
                "QueryStringLogging" => "log"
              }, {
                "MediaTypeId" => 8,
                "QueryStringLogging" => "no-log"
              }, {
                "MediaTypeId" => 14,
                "QueryStringLogging" => "log"
              }
            ]
          end
        end

        it 'returns the query string logging settings' do
          response = client.query_string_logging

          response.should be_an_instance_of(Hash)

          response[:http_large_object].should eq 'log'
          response[:hlo].should eq 'log'

          response[:http_small_object].should eq 'no-log'
          response[:hso].should eq 'no-log'

          response[:application_delivery_network].should eq 'log'
          response[:adn].should eq 'log'
        end
      end

      context 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the logging settings' do
          response = @client.query_string_logging
          response.should be_an_instance_of(Hash)
        end
      end
    end

    describe 'a specific query string logging setting' do
      context 'stubbed request' do
        before do
          client.should_receive(:get).with('querystringlogging?mediatypeid=3') do
            {
              "MediaTypeId" => 3,
              "QueryStringLogging" => "log"
            }
          end
        end

        it 'returns the query string logging setting' do
          response = client.query_string_logging(:http_large_object)

          response.should be_an_instance_of(Hash)

          response[:http_large_object].should eq 'log'
          response[:hlo].should eq 'log'
        end
      end

      context 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the logging setting' do
          response = @client.query_string_logging(:http_large_object)
          response.should be_an_instance_of(Hash)
        end
      end
    end
  end

  describe '.update_query_string_logging' do
    context 'stubbed request' do
      before do
        client.should_receive(:put).with('querystringlogging', { "MediaTypeId" => 3, "QueryStringLogging" => "no-log" })
      end

      it 'returns the compression settings' do
        response = client.update_query_string_logging(:http_large_object, 'no-log')

        response.should be_nil
      end
    end
  end

end
