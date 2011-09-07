require 'spec_helper'

describe RecurringJob do

  describe ".delay_invoices_processing" do
    it "delays invoices_processing if not already delayed" do
      expect { RecurringJob.delay_invoices_processing }.to change(Delayed::Job.where(:handler.matches => '%RecurringJob%invoices_processing%'), :count).by(1)
    end

    it "doesn't delay invoices_processing if already delayed" do
      RecurringJob.delay_invoices_processing
      expect { RecurringJob.delay_invoices_processing }.to_not change(Delayed::Job.where(:handler.matches => '%RecurringJob%invoices_processing%'), :count)
    end
  end

  describe ".invoices_processing" do
    it "calls 4 methods" do
      Invoice.should_receive(:update_pending_dates_for_first_not_paid_invoices)
      Site.should_receive(:activate_or_downgrade_sites_leaving_trial)
      Site.should_receive(:renew_active_sites)
      Transaction.should_receive(:charge_invoices)

      RecurringJob.invoices_processing
    end

    it "calls delay_invoices_processing" do
      RecurringJob.should_receive(:delay_invoices_processing)

      RecurringJob.invoices_processing
    end
  end

  describe ".launch_all" do
    use_vcr_cassette "recurring_job/launch_all"

    RecurringJob::NAMES.each do |name|
      it "launches #{name} recurring job" do
        Delayed::Job.already_delayed?(name).should be_false
        subject.launch_all
        Delayed::Job.already_delayed?(name).should be_true
      end
    end
  end

  describe ".supervise" do
    use_vcr_cassette "recurring_job/supervise"

    it "doesn't notify if all recurring jobs are delayed" do
      subject.launch_all
      Notify.should_not_receive(:send)
      subject.supervise
    end

    it "notifies if all recurring jobs aren't delayed" do
      subject.launch_all
      Delayed::Job.last.delete
      Notify.should_receive(:send)
      subject.supervise
    end
  end

end
