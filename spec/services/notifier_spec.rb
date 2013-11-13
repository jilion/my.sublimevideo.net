require 'fast_spec_helper'
require 'honeybadger'

require 'wrappers/prowl_wrapper'
require 'services/notifier'

describe Notifier do

  describe "send method" do
    let(:message) { 'exception message' }
    let(:exception) { Exception.new('exception') }

    before do
      allow(Honeybadger).to receive(:notify_or_ignore)
      allow(ProwlWrapper).to receive(:notify)
      Rails.stub_chain(:env, :production?) { false }
      Rails.stub_chain(:env, :staging?) { false }
    end

    it "should notify via Honeybadger" do
      expect(Honeybadger).to receive(:notify_or_ignore).with(Exception.new(message))
      Notifier.send(message)
    end

    it "should notify via Honeybadger with exception" do
      expect(Honeybadger).to receive(:notify_or_ignore).with(exception, error_message: message)
      Notifier.send(message, exception: exception)
    end

    it "should notify via Honeybadger with message as exception" do
      expect(Honeybadger).to receive(:notify_or_ignore).with(exception)
      Notifier.send(exception)
    end

    it "should notify via prowl in prod env" do
      Rails.stub_chain(:env, :production?) { true }
      expect(ProwlWrapper).to receive(:notify).with(message)
      Notifier.send(message)
      Rails.stub_chain(:env, :production?) { false }
    end

    it "should not notify via prowl in test env" do
      expect(ProwlWrapper).not_to receive(:notify).with(message)
      Notifier.send(message)
    end

  end

end
