require 'spec_helper'

describe EdgeCast::Client::Media::Log::Settings::Format do

  let(:client) { EdgeCast::Client.new }

  describe '.format' do
    describe 'all log format settings' do
      context 'stubbed request' do
        before do
          client.should_receive(:get).with('logformat') do
            {
              'AN' => "0001",
              'BaseFormat' => 1,
              'CustomFieldHeader' => 'x-ec_custom-1',
              'DateTimeFormat' => 0,
              'RemoveContentAccessPoint' => 0,
              'ShowCustomField' => 1
            }
          end
        end

        it 'returns the log format settings' do
          response = client.log_format

          response[:base_format].should eq 1
          response[:custom_field_header].should eq 'x-ec_custom-1'
          response[:date_time_format].should eq 0
          response[:remove_content_access_point].should eq 0
          response[:show_custom_field].should eq 1
        end
      end

      context 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the log format settings' do
          response = @client.log_format

          response.should be_an_instance_of(Hash)
        end
      end
    end
  end

  describe '.update_format' do
    context 'stubbed request' do
      before do
        client.should_receive(:put).with('logformat', {
          'BaseFormat' => 1,
          'CustomFieldHeader' => 'x-ec_custom-1',
          'DateTimeFormat' => 0,
          'RemoveContentAccessPoint' => 0,
          'ShowCustomField' => 1
        })
      end

      it 'returns the compression settings' do
        response = client.update_log_format(
          :base_format => 1,
          :custom_field_header => 'x-ec_custom-1',
          :date_time_format => 0,
          :remove_content_access_point => 0,
          :show_custom_field => 1
        )

        response.should be_nil
      end
    end
  end

end
