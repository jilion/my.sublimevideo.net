require 'fast_spec_helper'
require 'configurator'
require 'active_support/core_ext'
require 'tinder'
require 'config/vcr'

require 'wrappers/campfire_wrapper'

describe CampfireWrapper do

  describe "Class methods" do
    subject { CampfireWrapper }

    its(:subdomain) { should eq 'jilion' }
    its(:api_token) { should eq '902e80d1986be4138f3092d10ee67d468c96d9bf' }
    its(:default_room) { should eq 'SV Dev' }
  end

  describe "#room" do
    use_vcr_cassette "campfire/room"

    context "with default room" do
      let(:wrapper) { CampfireWrapper.new }

      it "has SV Dev room" do
        wrapper.room.name.should eq 'SV Dev'
      end
    end
    context "with default room" do
      let(:wrapper) { CampfireWrapper.new('Jilion') }

      it "has SV Dev room" do
        wrapper.room.name.should eq 'Jilion'
      end
    end
  end

  describe ".post" do
    let(:message) { "Hello I'm a test message" }
    let(:room_name) { 'Jilion'}

    context "in production" do
      use_vcr_cassette "campfire/production_message"
      before { Rails.stub(:env) { 'production' } }

      it "speaks to the room" do
        CampfireWrapper.post(message, room: room_name)
        CampfireWrapper.new(room_name).room.recent(1).first.body.should eq message
      end
    end

    context "in staging" do
      use_vcr_cassette "campfire/staging_message"
      before { Rails.stub(:env) { 'staging' } }

      it "speaks to the room" do
        CampfireWrapper.post(message, room: room_name)
        CampfireWrapper.new(room_name).room.recent(1).first.body.should eq "[STAGING] #{message}"
      end
    end

    it "posts only on Production or Staging env" do
      Rails.stub(:env) { 'test' }
      CampfireWrapper.should_not_receive(:new)
      CampfireWrapper.post(message, room: room_name)
    end
  end

end
