require 'fast_spec_helper'

require 'wrappers/prowl_wrapper'

describe ProwlWrapper do
  let(:message) { 'Hello I am a test message' }

  describe '#notify' do

    it 'speaks to the room' do
      described_class.client.should_receive(:add).with(event: 'Alert', priority: 2, description: message)

      described_class.new(message).notify
    end
  end

  describe '.notify' do
    it 'create a new instance and sends it #notify' do
      wrapper = double('SettingsFormatter')
      described_class.should_receive(:new).with(message) { wrapper }
      wrapper.should_receive(:notify)

      described_class.notify(message)
    end
  end

end
