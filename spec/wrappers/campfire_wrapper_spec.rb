require 'fast_spec_helper'
require 'config/vcr'

require 'wrappers/campfire_wrapper'

describe CampfireWrapper, :vcr do

  describe '#room' do
    context 'with default room' do
      let(:wrapper) { described_class.new }

      it 'has SV Dev room' do
        expect(wrapper.room.name).to eq 'SV Dev'
      end
    end

    context 'with default room' do
      let(:wrapper) { described_class.new('Jilion') }

      it 'has SV Dev room' do
        expect(wrapper.room.name).to eq 'Jilion'
      end
    end
  end

  describe '.post' do
    let(:message) { 'Hello I am a test message' }
    let(:room_name) { 'Jilion'}

    context 'in production' do
      before { allow(Rails).to receive(:env) { 'production' } }

      it 'speaks to the room' do
        described_class.post(message, room: room_name)
        expect(described_class.new(room_name).room.recent(limit: 1).first.body).to eq message
      end
    end

    context 'in staging' do
      before { allow(Rails).to receive(:env) { 'staging' } }

      it 'speaks to the room' do
        described_class.post(message, room: room_name)
        expect(described_class.new(room_name).room.recent(limit: 1).first.body).to eq "[STAGING] #{message}"
      end
    end

    it 'posts only on Production or Staging env' do
      allow(Rails).to receive(:env) { 'test' }
      expect(described_class).not_to receive(:new)
      described_class.post(message, room: room_name)
    end
  end

end
