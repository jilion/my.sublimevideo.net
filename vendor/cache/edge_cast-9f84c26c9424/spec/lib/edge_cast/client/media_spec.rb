require 'spec_helper'

describe EdgeCast::Client::Media do

  describe '.from_code' do
    described_class::TYPES.each do |type|
      it "returns #{type} for #{type[:code]} for load action" do
        described_class.from_code(type[:code]).should eq type
      end
    end
  end

  describe '.valid_type?' do
    { :windows_media_streaming => false, :wms => false,
      :flash_media_streaming => true, :fms => true,
      :http_large_object => true, :hlo => true,
      :http_small_object => true, :hso => true,
      :application_delivery_network => true, :adn => true
    }.each do |k, v|
      it "returns #{v} for #{k} for load action" do
        described_class.valid_type?(k, :load).should eq v
      end
    end

    { :windows_media_streaming => true, :wms => true,
      :flash_media_streaming => true, :fms => true,
      :http_large_object => true, :hlo => true,
      :http_small_object => true, :hso => true,
      :application_delivery_network => true, :adn => true
    }.each do |k, v|
      it "returns #{v} for #{k} for purge action" do
        described_class.valid_type?(k, :purge).should eq v
        described_class.valid_type?(k).should eq v
      end
    end
  end

  describe '.from_key' do
    { :windows_media_streaming => 1, :wms => 1,
      :flash_media_streaming => 2, :fms => 2,
      :http_large_object => 3, :hlo => 3,
      :http_small_object => 8, :hso => 8,
      :application_delivery_network => 14, :adn => 14
    }.each do |k, v|
      it "returns #{v} for #{k}" do
        described_class.from_key(k)[:code].should eq v
      end
    end
  end

end
