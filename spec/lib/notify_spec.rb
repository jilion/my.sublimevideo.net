require 'fast_spec_helper'
require 'airbrake'
require File.expand_path('lib/notify')

describe Notify do

  describe "send method" do
    let(:message) { 'exception message' }
    let(:exception) { Exception.new('exception') }

    before do
      Airbrake.stub(:notify)
      ProwlWrapper.stub(:notify)
      Rails.stub_chain(:env, :production?) { false }
      Rails.stub_chain(:env, :staging?) { false }
    end

    it "should notify via airbrake" do
      Airbrake.should_receive(:notify).with(Exception.new(message))
      Notify.send(message)
    end

    it "should notify via airbrake with exception" do
      Airbrake.should_receive(:notify).with(exception, error_message: message)
      Notify.send(message, exception: exception)
    end

    it "should notify via airbrake with message as exception" do
      Airbrake.should_receive(:notify).with(exception)
      Notify.send(exception)
    end

    it "should notify via prowl in prod env" do
      Rails.stub_chain(:env, :production?) { true }
      ProwlWrapper.should_receive(:notify).with(message)
      Notify.send(message)
      Rails.stub_chain(:env, :production?) { false }
    end

    it "should not notify via prowl in test env" do
      ProwlWrapper.should_not_receive(:notify).with(message)
      Notify.send(message)
    end

  end

end
