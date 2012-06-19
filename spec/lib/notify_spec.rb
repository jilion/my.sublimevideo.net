require 'spec_helper'

describe Notify do

  describe "send method" do
    before do
      Airbrake.stub(:notify)
      Notify.stub(:prowl)
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
      Notify.should_receive(:prowl).with(message)
      Rails.env = "production"
      Notify.send(message)
      Rails.env = "test"
    end

    it "should not notify via prowl in test env" do
      message = 'Yo!'
      Notify.should_not_receive(:prowl).with(message)
      Notify.send(message)
    end

  end

end
