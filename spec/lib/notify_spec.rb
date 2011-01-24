require 'spec_helper'

describe Notify do

  describe "send method" do
    before(:each) do
      HoptoadNotifier.stub(:notify)
      Notify.stub(:prowl)
    end

    it "should notify via hoptoad" do
      message = 'Yo!'
      HoptoadNotifier.should_receive(:notify).with(:error_message => message)
      Notify.send(message)
    end

    it "should notify via hoptoad with exception" do
      message = 'Yo!'
      HoptoadNotifier.should_receive(:notify).with("exception", :error_message => message)
      Notify.send(message, :exception => "exception")
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
