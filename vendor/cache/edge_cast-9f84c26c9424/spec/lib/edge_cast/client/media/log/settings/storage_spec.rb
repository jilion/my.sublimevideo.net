require 'spec_helper'

describe EdgeCast::Client::Media::Log::Settings::Storage do

  let(:client) { EdgeCast::Client.new }

  describe '.storage' do
    describe 'all log storage settings' do
      context 'stubbed request' do
        before do
          client.should_receive(:get).with('logstorage') do
            {
              'AN' => '0001',
              'DaysToKeep' => -1,
              'IsEnabled' => 1,
              'MediaTypeStatuses' => [{
                'IsEnabled' => 1,
                'MediaTypeId' => 3
              }, {
                'IsEnabled' => 1,
                'MediaTypeId' => 8
              }, {
                'IsEnabled' => 1,
                'MediaTypeId' => 1
              }, {
                'IsEnabled' => 0,
                'MediaTypeId' => 14
              }]
            }
          end
        end

        it 'returns the log storage settings' do
          response = client.log_storage

          response.should be_an_instance_of(Hash)

          response[:days_to_keep].should eq -1
          response[:is_enabled].should eq 1
          response[:media_type_statuses].should eq [
            {"IsEnabled"=>1, "MediaTypeId"=>3},
            {"IsEnabled"=>1, "MediaTypeId"=>8},
            {"IsEnabled"=>1, "MediaTypeId"=>1},
            {"IsEnabled"=>0, "MediaTypeId"=>14}
          ]
        end
      end

      context 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the log storage settings' do
          response = @client.log_storage
          response.should be_an_instance_of(Hash)
        end
      end
    end

  end

  describe '.update_log_storage' do
    context 'stubbed request' do
      before do
        client.should_receive(:put).with('logstorage', { "DaysToKeep" => 1, "IsEnabled" => 0, 'MediaTypeStatuses' => [{
            'IsEnabled' => 1,
            'MediaTypeId' => 3
          }, {
            'IsEnabled' => 1,
            'MediaTypeId' => 8
          }, {
            'IsEnabled' => 1,
            'MediaTypeId' => 1
          }, {
            'IsEnabled' => 0,
            'MediaTypeId' => 14
          }]
        })
      end

      it 'returns the compression settings' do
        response = client.update_log_storage(:days_to_keep => 1, :is_enabled => 0, :media_type_statuses => [
            {"IsEnabled"=>1, "MediaTypeId"=>3},
            {"IsEnabled"=>1, "MediaTypeId"=>8},
            {"IsEnabled"=>1, "MediaTypeId"=>1},
            {"IsEnabled"=>0, "MediaTypeId"=>14}
          ])

        response.should be_nil
      end
    end
  end

end
