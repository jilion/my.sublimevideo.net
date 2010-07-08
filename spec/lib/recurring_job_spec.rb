require 'spec_helper'

describe RecurringJob do
  subject { described_class }
  
  describe "launch_all method" do
    
    RecurringJob::NAMES.each do |name|
      it "should launch #{name} recurring job" do
        Delayed::Job.already_delayed?(name).should be_false
        subject.launch_all
        Delayed::Job.already_delayed?(name).should be_true
      end
    end
    
  end
  
  describe "supervise method" do
    
    it "should do nothing all recurring jobs are delayed" do
      subject.launch_all
      HoptoadNotifier.should_not_receive(:notify)
      subject.supervise
    end
    
    it "should nbotify if all recurring jobs aren't delayed" do
      subject.launch_all
      Delayed::Job.last.delete
      HoptoadNotifier.should_receive(:notify)
      subject.supervise
    end
    
  end
  
end