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
    
    it "should notify via prowl" do
      message = 'Yo!'
      Notify.should_receive(:prowl).with(message)
      Notify.send(message)
    end
    
  end
  
end
