require 'fast_spec_helper'
require 'airbrake'
require 'active_support/core_ext'
require File.expand_path('lib/notify')

describe Notify do

  describe "send method" do
    before do
      Airbrake.stub(:notify)
      ProwlWrapper.stub(:notify)
      Rails.stub_chain(:env, :production?) { false }
      Rails.stub_chain(:env, :staging?) { false }
    end

    it "should notify via airbrake" do
      message = 'Yo!'
      Airbrake.should_receive(:notify).with(Exception.new(message))
      Notify.send(message)
    end

    it "should notify via airbrake with exception" do
      message = 'Yo!'
      Airbrake.should_receive(:notify).with(Exception.new("Yo! // exception: exception"))
      Notify.send(message, exception: "exception")
    end

    it "should notify via prowl in prod env" do
      message = 'Yo!'
      Rails.stub_chain(:env, :production?) { true }
      ProwlWrapper.should_receive(:notify).with(message)
      Notify.send(message)
    end

    it "should not notify via prowl in test env" do
      message = 'Yo!'
      ProwlWrapper.should_not_receive(:notify).with(message)
      Notify.send(message)
    end

  end

end
