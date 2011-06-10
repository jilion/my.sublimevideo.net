require 'spec_helper'

describe RecurringJob do

  describe ".delay_invoices_processing" do
    it "should delay invoices_processing if not already delayed" do
      expect { RecurringJob.delay_invoices_processing }.to change(Delayed::Job.where(:handler.matches => '%RecurringJob%invoices_processing%'), :count).by(1)
    end

    it "should not delay invoices_processing if already delayed" do
      RecurringJob.delay_invoices_processing
      expect { RecurringJob.delay_invoices_processing }.to_not change(Delayed::Job.where(:handler.matches => '%RecurringJob%invoices_processing%'), :count)
    end
  end

  describe ".invoices_processing" do
    it "should call 3 methods" do
      Invoice.should_receive(:update_pending_dates_for_first_not_paid_invoices)
      Site.should_receive(:renew_active_sites)
      Transaction.should_receive(:charge_invoices)
      RecurringJob.invoices_processing
    end

    it "should delay invoices_processing if not already delayed" do
      expect { RecurringJob.invoices_processing }.to change(Delayed::Job.where(:handler.matches => '%RecurringJob%invoices_processing%'), :count).by(1)
    end
  end

  describe ".launch_all" do
    RecurringJob::NAMES.each do |name|
      it "should launch #{name} recurring job" do
        Delayed::Job.already_delayed?(name).should be_false
        subject.launch_all
        Delayed::Job.already_delayed?(name).should be_true
      end
    end
  end

  describe ".supervise" do
    it "should do nothing all recurring jobs are delayed" do
      subject.launch_all
      Notify.should_not_receive(:send)
      subject.supervise
    end

    it "should notify if all recurring jobs aren't delayed" do
      subject.launch_all
      Delayed::Job.last.delete
      Notify.should_receive(:send)
      subject.supervise
    end
  end

end
