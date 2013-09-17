require 'fast_spec_helper'
require 'config/vcr'

require 'wrappers/campfire_wrapper'

describe CampfireWrapper do

  describe '#room' do
    use_vcr_cassette 'campfire/room'

    context 'with default room' do
      let(:wrapper) { described_class.new }

      it 'has SV Dev room' do
        wrapper.room.name.should eq 'SV Dev'
      end
    end

    context 'with default room' do
      let(:wrapper) { described_class.new('Jilion') }

      it 'has SV Dev room' do
        wrapper.room.name.should eq 'Jilion'
      end
    end
  end

  describe '.post' do
    let(:message) { 'Hello I am a test message' }
    let(:room_name) { 'Jilion'}

    context 'in production' do
      use_vcr_cassette 'campfire/production_message'
      before { Rails.stub(:env) { 'production' } }

      it 'speaks to the room' do
        described_class.post(message, room: room_name)
        described_class.new(room_name).room.recent(limit: 1).first.body.should eq message
      end
    end

    context 'in staging' do
      use_vcr_cassette 'campfire/staging_message'
      before { Rails.stub(:env) { 'staging' } }

      it 'speaks to the room' do
        described_class.post(message, room: room_name)
        described_class.new(room_name).room.recent(limit: 1).first.body.should eq "[STAGING] #{message}"
      end
    end

    it 'posts only on Production or Staging env' do
      Rails.stub(:env) { 'test' }
      described_class.should_not_receive(:new)
      described_class.post(message, room: room_name)
    end
  end

end
