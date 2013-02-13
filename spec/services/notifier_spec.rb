require 'fast_spec_helper'
require 'airbrake'

require 'wrappers/prowl_wrapper'
require 'services/notifier'

describe Notifier do

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
      Notifier.send(message)
    end

    it "should notify via airbrake with exception" do
      Airbrake.should_receive(:notify).with(exception, error_message: message)
      Notifier.send(message, exception: exception)
    end

    it "should notify via airbrake with message as exception" do
      Airbrake.should_receive(:notify).with(exception)
      Notifier.send(exception)
    end

    it "should notify via prowl in prod env" do
      Rails.stub_chain(:env, :production?) { true }
      ProwlWrapper.should_receive(:notify).with(message)
      Notifier.send(message)
      Rails.stub_chain(:env, :production?) { false }
    end

    it "should not notify via prowl in test env" do
      ProwlWrapper.should_not_receive(:notify).with(message)
      Notifier.send(message)
    end

  end

end
