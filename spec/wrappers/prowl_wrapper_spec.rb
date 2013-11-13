require 'fast_spec_helper'

require 'wrappers/prowl_wrapper'

describe ProwlWrapper do
  let(:message) { 'Hello I am a test message' }

  describe '#notify' do

    it 'speaks to the room' do
      expect(described_class.client).to receive(:add).with(event: 'Alert', priority: 2, description: message)

      described_class.new(message).notify
    end
  end

  describe '.notify' do
    it 'create a new instance and sends it #notify' do
      wrapper = double('SettingsFormatter')
      expect(described_class).to receive(:new).with(message) { wrapper }
      expect(wrapper).to receive(:notify)

      described_class.notify(message)
    end
  end

end
