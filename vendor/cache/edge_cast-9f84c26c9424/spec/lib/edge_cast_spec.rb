require 'spec_helper'

describe EdgeCast do
  after do
    EdgeCast.reset
  end

  describe '.respond_to?' do
    it 'takes an optional argument' do
      EdgeCast.respond_to?(:new, true).should be_true
    end
  end

  describe '.new' do
    it 'returns a EdgeCast::Client' do
      EdgeCast.new.should be_a EdgeCast::Client
    end
  end

  describe '.adapter' do
    it 'returns the default adapter' do
      EdgeCast.adapter.should eq EdgeCast::Config::DEFAULT_ADAPTER
    end
  end

  describe '.adapter=' do
    it 'sets the adapter' do
      EdgeCast.adapter = :typhoeus
      EdgeCast.adapter.should eq :typhoeus
    end
  end

  describe '.user_agent' do
    it 'returns the default user agent' do
      EdgeCast.user_agent.should eq EdgeCast::Config::DEFAULT_USER_AGENT
    end
  end

  describe '.user_agent=' do
    it 'sets the user_agent' do
      EdgeCast.user_agent = 'Custom User Agent'
      EdgeCast.user_agent.should eq 'Custom User Agent'
    end
  end

  describe '.configure' do
    EdgeCast::Config::VALID_OPTIONS_KEYS.each do |key|
      it "sets the #{key}" do
        EdgeCast.configure do |config|
          config.send("#{key}=", key)
          EdgeCast.send(key).should eq key
        end
      end
    end
  end

end
