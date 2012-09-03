require 'spec_helper'

describe SiteModules::Billing do

  describe 'Instance Methods', :plans do

    describe '#invoices_open?' do
      let(:site) { create(:site) }

      context "with no options" do
        it "should be true if invoice have the renew flag == false" do
          invoice = create(:invoice, state: 'open', site: site, renew: false)
          invoice.renew.should be_false
          site.invoices_open?.should be_true
        end

        it "should be true if invoice have the renew flag == true" do
          invoice = create(:invoice, state: 'open', site: site, renew: true)
          invoice.renew.should be_true
          site.invoices_open?.should be_true
        end
      end
    end # #invoices_open?

    describe '#invoices_failed?' do
      subject do
        site = create(:site)
        create(:invoice, site: site , state: 'failed')
        site
      end

      its(:invoices_failed?) { should be_true }
    end # #invoices_failed?

    describe '#invoices_waiting?' do
      subject do
        site = create(:site)
        create(:invoice, site: site , state: 'waiting')
        site
      end

      its(:invoices_waiting?) { should be_true }
    end # #invoices_waiting?

    describe '#instant_charging?' do
      let(:site) { create(:site) }

      it 'returns false' do
        site.instance_variable_set('@instant_charging', false)
        site.should_not be_instant_charging
      end

      it 'returns true' do
        site.instance_variable_set('@instant_charging', true)
        site.should be_instant_charging
      end
    end # #instant_charging?

    describe '#will_be_in_free_plan?' do

      context "site in free plan" do
        subject { create(:site, plan_id: @free_plan.id) }

        it { should_not be_will_be_in_free_plan }
      end

      context "site in paid plan" do
        subject { create(:site, plan_id: @paid_plan.id) }

        it { should_not be_will_be_in_free_plan }
      end

      context "site in build free plan" do
        subject { build(:new_site, plan_id: @free_plan.id) }

        it { should be_will_be_in_free_plan }
      end

      context "site is paid and updated to free" do
        subject do
          site = create(:site, plan_id: @paid_plan.id)
          site.plan_id = @free_plan.id
          site
        end

        it { should be_will_be_in_free_plan }
      end
    end # #will_be_in_free_plan?

    describe '#will_be_in_paid_plan?' do
      context "site in paid plan" do
        subject { create(:site, plan_id: @paid_plan.id) }

        it { should_not be_will_be_in_paid_plan }
      end

      context "site is free and updated to paid" do
        subject do
          site = create(:site, plan_id: @free_plan.id)
          site.plan_id = @paid_plan.id
          site
        end

        it { should be_will_be_in_paid_plan }
      end

      context "site is paid and updated to paid" do
        subject do
          site = create(:site, plan_id: @paid_plan.id)
          site.plan_id = @custom_plan.token
          site
        end

        its(:pending_plan_id) { should eq @custom_plan.id }
        it { should be_will_be_in_paid_plan }
      end

      context "site is paid and updated to free" do
        subject do
          site = create(:site, plan_id: @paid_plan.id)
          site.plan_id = @free_plan.id
          site
        end

        it { should_not be_will_be_in_paid_plan }
      end
    end # #will_be_in_paid_plan?

    describe '#will_be_in_unpaid_plan?' do
      context "site in free plan" do
        subject { create(:site, plan_id: @free_plan.id) }

        it { should_not be_will_be_in_unpaid_plan }
      end

      context "site is free and updated to paid" do
        subject do
          site = create(:site, plan_id: @free_plan.id)
          site.pending_plan_id = @paid_plan.id
          site
        end

        it { should_not be_will_be_in_unpaid_plan }
      end

      context "site is free and updated to trial" do
        subject do
          site = create(:site, plan_id: @free_plan.id)
          site.pending_plan_id = @trial_plan.id
          site
        end

        it { should be_will_be_in_unpaid_plan }
      end

      context "site is paid and updated to free" do
        subject do
          site = create(:site, plan_id: @paid_plan.id)
          site.pending_plan_id = @free_plan.id
          site
        end

        it { should be_will_be_in_unpaid_plan }
      end
    end # #will_be_in_unpaid_plan?

    describe '#in_or_will_be_in_paid_plan?' do
      context "site in paid plan" do
        subject { create(:site, plan_id: @paid_plan.id) }

        it { should be_in_or_will_be_in_paid_plan }
      end

      context "site is free and updated to paid" do
        subject do
          site = create(:site, plan_id: @free_plan.id)
          site.pending_plan_id = @paid_plan.id
          site
        end

        it { should be_in_or_will_be_in_paid_plan }
      end

      context "site is paid is now paid" do
        subject do
          site = create(:site, plan_id: @paid_plan.id)
          site.pending_plan_id = @free_plan.id
          site
        end

        it { should be_in_or_will_be_in_paid_plan }
      end
    end # #in_or_will_be_in_paid_plan?

    describe '#refunded?' do
      before do
        @site_refunded1     = create(:site, refunded_at: Time.now.utc).tap { |s| s.skip_password(:archive!) }
        @site_not_refunded1 = create(:site, refunded_at: Time.now.utc)
        @site_not_refunded2 = create(:site, refunded_at: nil).tap { |s| s.skip_password(:archive!) }
      end

      specify { @site_refunded1.should be_refunded }
      specify { @site_not_refunded1.should_not be_refunded }
      specify { @site_not_refunded2.should_not be_refunded }
    end # #refunded?

    describe '#last_paid_invoice' do
      context "with the last paid invoice not refunded" do
        let(:site) { create(:site_with_invoice, plan_id: @paid_plan.id) }

        it "should return the last paid invoice" do
          site.invoices.should have(1).item
          site.last_paid_invoice.should == site.invoices.paid.last
        end
      end

      context "with the last paid invoice refunded" do
        before do
          @site = create(:site_with_invoice, plan_id: @paid_plan.id)
          @site.invoices.should have(1).item
          @site.update_attribute(:refunded_at, Time.now.utc)
        end

        it "returns nil" do
          @site.refunded_at.should be_present
          @site.last_paid_invoice.should be_nil
        end
      end
    end # #last_paid_invoice

    describe '#last_paid_plan' do
      context "site with no invoice" do
        subject { create(:site, plan_id: @free_plan.id) }

        its(:last_paid_plan) { should be_nil }
      end

      context "site with at least one paid invoice" do
        before do
          @plan1 = create(:plan, price: 10_000)
          @plan2 = create(:plan, price: 5_000)
          @site  = create(:site_with_invoice, plan_id: @plan1.id)
          @site.plan_id = @plan2.id
        end

        it "should return the plan of the last InvoiceItem::Plan with an price > 0" do
          @site.last_paid_plan.should eq @plan1
        end
      end
    end # #last_paid_plan

    describe '#last_paid_plan_price' do
      context "site with no invoice" do
        subject { create(:site, plan_id: @free_plan.id) }

        its(:last_paid_plan_price) { should eq 0 }
      end

      context "site with at least one paid invoice" do
        before do
          @plan1 = create(:plan, price: 10_000)
          @plan2 = create(:plan, price: 5_000)
          @site  = create(:site_with_invoice, plan_id: @plan1.id)
          @site.plan_id = @plan2.id
        end

        it "should return the price of the last InvoiceItem::Plan with an price > 0" do
          @site.last_paid_plan_price.should eq @plan1.price
        end
      end
    end # #last_paid_plan_price
    describe '#set_first_paid_plan_started_at' do
      context 'free plan' do
        let(:site) { create(:new_site, plan_id: @free_plan.id) }

        it 'dont set first_paid_plan_started_at' do
          site.first_paid_plan_started_at.should be_nil
        end
      end

      context 'paid plan' do
        let(:site) { create(:new_site, plan_id: @paid_plan.id) }

        it 'sets first_paid_plan_started_at' do
          site.first_paid_plan_started_at.should be_present
        end
      end

      context 'downgrade' do
        let(:site) { create(:new_site, plan_id: @custom_plan.token) }
        before do
          site.first_paid_plan_started_at.should be_present
          @original_first_paid_plan_started_at = site.first_paid_plan_started_at
          sleep(0.5)
          site.update_attribute(:plan_id, @paid_plan.id)
        end

        it 'dont reset first_paid_plan_started_at' do
          site.reload.first_paid_plan_started_at.should eq @original_first_paid_plan_started_at
        end
      end

      context 'upgrade' do
        let(:site) { create(:new_site, plan_id: @paid_plan.id) }
        before do
          @original_first_paid_plan_started_at = site.first_paid_plan_started_at
          sleep(0.5)
          site.update_attribute(:plan_id, @custom_plan.token)
        end

        it 'dont reset first_paid_plan_started_at' do
          site.reload.first_paid_plan_started_at.should eq @original_first_paid_plan_started_at
        end
      end
    end # #set_first_paid_plan_started_at

    describe '#send_trial_started_email' do
      let(:site) { create(:site) }

      it 'send the trial started email' do
        site # eager-load site
        expect { site.send :send_trial_started_email }.to change(Delayed::Job.where { handler =~ '%Class%trial_has_started%' }, :count).by(1)
      end
    end

    describe '#create_and_charge_invoice' do
      describe 'creation' do
        let(:trial_site) { build(:new_site, plan_id: @trial_plan.id) }
        let(:free_site)  { build(:new_site, plan_id: @free_plan.id) }
        let(:paid_site)  { build(:new_site, plan_id: @paid_plan.id) }
        let(:sponsored_site) do
          s = build(:new_site)
          s.send(:write_attribute, :pending_plan_id, @sponsored_plan.id)
          s
        end

        context 'trial plan' do
          it 'dont create any invoice' do
            expect { trial_site.save! }.to_not change(trial_site.invoices, :count)
          end
        end

        context 'free plan' do
          it 'dont create any invoice' do
            expect { free_site.save! }.to_not change(free_site.invoices, :count)
          end
        end

        context 'paid plan' do
          it 'creates an invoice' do
            expect { paid_site.save! }.to change(paid_site.invoices, :count).by(1)
          end
        end

        context 'sponsored plan' do
          it 'dont create an invoice' do
            expect { sponsored_site.save! }.to_not change(sponsored_site.invoices, :count)
          end
        end
      end

      describe 'persisted site' do
        let(:trial_site)     { create(:site, plan_id: @trial_plan.id) }
        let(:free_site)      { create(:site, plan_id: @free_plan.id) }
        let(:paid_site)      { create(:site, plan_id: @paid_plan.id) }
        let(:custom_site)    { create(:site, plan_id: @custom_plan.token) }
        let(:sponsored_site) do
          s = create(:site, plan_id: @paid_plan.id)
          s.send(:write_attribute, :plan_id, @sponsored_plan.id)
          s
        end

        describe 'saved during first cycle' do
          context 'trial plan' do
            it 'dont create an invoice' do
              trial_site.prepare_pending_attributes
              expect { trial_site.save! }.to_not change(trial_site.invoices, :count)
            end
          end

          context 'free plan' do
            it 'dont create an invoice' do
              free_site.prepare_pending_attributes
              expect { free_site.save! }.to_not change(free_site.invoices, :count)
            end
          end

          context 'paid plan' do
            it 'dont create an invoice' do
              paid_site.prepare_pending_attributes
              expect { paid_site.save! }.to_not change(paid_site.invoices, :count)
            end
          end

          context 'sponsored plan' do
            it 'dont create an invoice' do
              sponsored_site.prepare_pending_attributes
              expect { sponsored_site.save! }.to_not change(free_site.invoices, :count)
            end
          end
        end

        describe 'saved during second cycle' do
          before do
            trial_site; free_site; paid_site; sponsored_site; # preload sites
            Timecop.travel(45.days.from_now)
          end
          after { Timecop.return }

          context 'trial plan' do
            it 'dont create an invoice' do
              trial_site.prepare_pending_attributes
              expect { trial_site.save! }.to_not change(trial_site.invoices, :count)
            end
          end

          context 'free plan' do
            it 'dont create an invoice' do
              free_site.prepare_pending_attributes
              expect { free_site.save! }.to_not change(free_site.invoices, :count)
            end
          end

          context 'paid plan' do
            it 'creates an invoice' do
              paid_site.prepare_pending_attributes
              expect { paid_site.save! }.to change(paid_site.invoices, :count).by(1)
            end
          end

          context 'sponsored plan' do
            it 'dont create an invoice' do
              sponsored_site.prepare_pending_attributes
              expect { sponsored_site.save! }.to_not change(free_site.invoices, :count)
            end
          end
        end

        describe 'upgrade' do
          before do
            trial_site; free_site; paid_site; sponsored_site; # preload sites
          end

          context 'trial plan' do
            it 'creates an invoice' do
              trial_site.plan_id = @paid_plan.id
              expect { trial_site.skip_password(:save!) }.to change(trial_site.invoices, :count).by(1)
              expect { trial_site.skip_password(:save!) }.to_not change(trial_site.invoices, :count)
            end
          end

          context 'free plan' do
            it 'creates an invoice' do
              free_site.plan_id = @paid_plan.id
              expect { free_site.skip_password(:save!) }.to change(free_site.invoices, :count).by(1)
              expect { free_site.skip_password(:save!) }.to_not change(free_site.invoices, :count)
            end
          end

          context 'paid plan' do
            it 'creates an invoice' do
              paid_site.plan_id = @custom_plan.token
              expect { paid_site.skip_password(:save!) }.to change(paid_site.invoices, :count).by(1)
              expect { paid_site.skip_password(:save!) }.to_not change(paid_site.invoices, :count)
            end
          end

          context 'sponsored plan' do
            it 'creates an invoice' do
              sponsored_site.plan_id = @paid_plan.id
              expect { sponsored_site.skip_password(:save!) }.to change(sponsored_site.invoices, :count).by(1)
              expect { sponsored_site.skip_password(:save!) }.to_not change(sponsored_site.invoices, :count)
            end
          end
        end

        describe 'downgrade' do
          context 'paid plan to free plan' do
            it 'dont create an invoice' do
              paid_site.plan_id = @free_plan.id
              expect { paid_site.skip_password(:save!) }.to_not change(paid_site.invoices, :count)
              Timecop.travel(45.days.from_now)
              paid_site.prepare_pending_attributes # simulate renew

              expect { paid_site.skip_password(:save!) }.to_not change(paid_site.invoices, :count)
              Timecop.return
            end
          end

          context 'paid plan to paid plan' do
            it 'dont create an invoice, but does on renew' do
              custom_site.plan_id = @paid_plan.id
              expect { custom_site.skip_password(:save!) }.to_not change(custom_site.invoices, :count)

              Timecop.travel(45.days.from_now)
              custom_site.prepare_pending_attributes # simulate renew

              expect { custom_site.skip_password(:save!) }.to change(custom_site.invoices, :count).by(1)
              expect { custom_site.skip_password(:save!) }.to_not change(custom_site.invoices, :count)
              Timecop.return
            end
          end

          context 'sponsored plan' do
            it 'creates an invoice' do
              sponsored_site.plan_id = @free_plan.id
              expect { sponsored_site.skip_password(:save!) }.to_not change(sponsored_site.invoices, :count)
            end
          end
        end
      end
    end # #create_and_charge_invoice

    describe '#created? & #upgraded? #updated_to_paid_plan? & #updated_to_unpaid_plan? & #renewed?' do
      context 'new site in free' do
        subject { build(:new_site, plan_id: @free_plan.id) }

        it { should     be_created }
        it { should_not be_upgraded }
        it { should_not be_updated_to_paid_plan }
        it { should     be_updated_to_unpaid_plan }
        it { should_not be_renewed }
      end

      context 'new site in paid' do
        subject { build(:new_site, plan_id: @paid_plan.id) }

        it { should be_created }
        it { should_not be_upgraded }
        it { should     be_updated_to_paid_plan }
        it { should_not be_updated_to_unpaid_plan }
        it { should_not be_renewed }
      end

      context 'persisted site' do
        let(:site) { create(:site, plan_id: @paid_plan.id) }
        subject { site }

        it { should_not be_created }
        it { should_not be_upgraded }
        it { should_not be_updated_to_paid_plan }
        it { should_not be_updated_to_unpaid_plan }
        it { should_not be_renewed }

        context 'renew' do
          before do
            site.pending_plan_cycle_started_at = Time.now
          end

          it { should_not be_created }
          it { should_not be_upgraded }
          it { should_not be_updated_to_paid_plan }
          it { should_not be_updated_to_unpaid_plan }
          it { should     be_renewed }

          context 'with downgrade' do
            before do
              site.pending_plan_id = @free_plan.id
            end

            it { should_not be_created }
            it { should_not be_upgraded }
            it { should_not be_updated_to_paid_plan }
            it { should     be_updated_to_unpaid_plan }
            it { should     be_renewed }
          end
        end

        context 'will upgrade' do
          before do
            site.pending_plan_id = @custom_plan.id
          end

          it { should_not be_created }
          it { should     be_upgraded }
          it { should     be_updated_to_paid_plan }
          it { should_not be_updated_to_unpaid_plan }
          it { should_not be_renewed }
        end

        context 'will downgrade to paid' do
          let(:site) { create(:site, plan_id: @custom_plan.token) }
          before do
            site.pending_plan_id = @paid_plan.id
          end

          it { should_not be_created }
          it { should_not be_upgraded }
          it { should     be_updated_to_paid_plan }
          it { should_not be_updated_to_unpaid_plan }
          it { should_not be_renewed }
        end

        context 'will downgrade to free' do
          before do
            site.pending_plan_id = @free_plan.id
          end

          it { should_not be_created }
          it { should_not be_upgraded }
          it { should_not be_updated_to_paid_plan }
          it { should     be_updated_to_unpaid_plan }
          it { should_not be_renewed }
        end
      end
    end # #created? & #upgraded? #updated_to_paid_plan? & #updated_to_unpaid_plan? & #renewed?

  end # Instance Methods

end
