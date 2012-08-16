require 'spec_helper'

describe EdgeCast::Client::Media::Cache::Settings::Compression do

  let(:client) { EdgeCast::Client.new }

  describe '.compression' do
    describe 'all compression settings' do
      context 'stubbed request' do
        before do
          client.should_receive(:get).with('compression') do
            [
              {
                "MediaTypeId" => 3,
                "Status" => 1,
                "ContentTypes" => ["text\/plain", "text\/html", "text\/css", "application\/x-javascript", "text\/javascript"]
              }, {
                "MediaTypeId" => 8,
                "Status" => 0,
                "ContentTypes" => [""]
              }, {
                "MediaTypeId" => 14,
                "Status" => 1,
                "ContentTypes" => ["text\/plain"]
              }
            ]
          end
        end

        it 'returns the compression settings' do
          response = client.compression

          response.should be_an_instance_of(Hash)

          response[:http_large_object][:status].should eq 1
          response[:hlo][:status].should eq 1
          response[:http_large_object][:content_types].should eq ['text/plain', 'text/html', 'text/css', 'application/x-javascript', 'text/javascript']
          response[:hlo][:content_types].should eq ['text/plain', 'text/html', 'text/css', 'application/x-javascript', 'text/javascript']

          response[:http_small_object][:status].should eq 0
          response[:hso][:status].should eq 0

          response[:application_delivery_network][:status].should eq 1
          response[:adn][:status].should eq 1
          response[:application_delivery_network][:content_types].should eq ['text/plain']
          response[:adn][:content_types].should eq ['text/plain']
        end
      end

      context 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the compression settings' do
          response = @client.compression
          response.should == {}
        end
      end
    end

    describe 'a specific compression setting' do
      context 'stubbed request' do
        before do
          client.should_receive(:get).with('compression?mediatypeid=3') do
            {
              "MediaTypeId" => 3,
              "Status" => 1,
              "ContentTypes" => ["text\/plain", "text\/html", "text\/css", "application\/x-javascript", "text\/javascript"]
            }
          end
        end

        it 'returns the compression setting' do
          response = client.compression(:http_large_object)

          response.should be_an_instance_of(Hash)

          response[:http_large_object][:status].should eq 1
          response[:hlo][:status].should eq 1
          response[:http_large_object][:content_types].should eq ['text/plain', 'text/html', 'text/css', 'application/x-javascript', 'text/javascript']
          response[:hlo][:content_types].should eq ['text/plain', 'text/html', 'text/css', 'application/x-javascript', 'text/javascript']
        end
      end

      context 'real request', :vcr, :if => ForReal.ok? do
        it 'returns the compression setting' do
          response = @client.compression(:http_small_object)
          response.should == {}
        end
      end
    end
  end

  describe '.enable_compression' do
    context 'stubbed request' do
      before do
        client.should_receive(:put).with('compression', { "MediaTypeId" => 3, "ContentTypes" => ["text\/plain"], "Status" => 1 })
      end

      it 'returns the compression settings' do
        response = client.enable_compression(:http_large_object, ['text/plain'])

        response.should be_nil
      end
    end
  end

  describe '.disable_compression' do
    context 'stubbed request' do
      before do
        client.should_receive(:put).with('compression', { "MediaTypeId" => 3, "ContentTypes" => ["text\/plain"], "Status" => 0 })
      end

      it 'returns the compression settings' do
        response = client.disable_compression(:http_large_object, ['text/plain'])

        response.should be_nil
      end
    end
  end

end
