# coding: utf-8
require 'spec_helper'

describe Site do

  # describe "Test site with and without invoice" do
  #
  #   context "WITH INVOICE" do
  #     subject { FactoryGirl.create(:site_with_invoice) }
  #     it "should be slow" do
  #       start_time = Time.now
  #       subject.plan_id.should be_present
  #       subject.invoices.count.should == 1
  #       puts "WITH INVOICE: Done in #{Time.now - start_time} seconds!"
  #     end
  #   end
  #
  #   context "WITHOUT INVOICE" do
  #     subject { FactoryGirl.create(:site) }
  #     it "should be quick" do
  #       start_time = Time.now
  #       subject.plan_id.should be_present
  #       subject.invoices.count.should == 0
  #       puts "WITHOUT INVOICE: Done in #{Time.now - start_time} seconds!"
  #     end
  #   end
  #
  # end

  context "Factory" do
    before(:all) { @site = FactoryGirl.create(:site) }
    subject { @site.reload }

    its(:user)                          { should be_present }
    its(:plan)                          { should be_present }
    its(:pending_plan)                  { should be_nil }
    its(:hostname)                      { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)                 { should eql "127.0.0.1, localhost" }
    its(:extra_hostnames)               { should be_nil }
    its(:path)                          { should be_nil }
    its(:wildcard)                      { should be_false }
    its(:badged)                        { should be_false }
    its(:token)                         { should =~ /^[a-z0-9]{8}$/ }
    its(:license)                       { should_not be_present }
    its(:loader)                        { should_not be_present }
    its(:player_mode)                   { should eql "stable" }
    its(:plan_started_at)               { should eql Time.now.utc.midnight }
    its(:plan_cycle_started_at)         { should be_nil }
    its(:plan_cycle_ended_at)           { should be_nil }
    its(:pending_plan_started_at)       { should be_nil }
    its(:pending_plan_cycle_started_at) { should be_nil }
    its(:pending_plan_cycle_ended_at)   { should be_nil }
    its(:next_cycle_plan_id)            { should be_nil }

    it { should be_active } # initial state
    it { should_not be_in_free_plan }
    it { should be_valid }
  end

  describe "Associations" do
    before(:all) { @site = FactoryGirl.create(:site) }
    subject { @site }

    it { should belong_to :user }
    it { should belong_to :plan }
    it { should have_many :invoices }

    describe "last_invoice" do
      subject { FactoryGirl.create(:site_with_invoice, plan_id: @paid_plan.id) }

      it "should return the last paid invoice" do
        subject.last_invoice.should == subject.invoices.last
      end
    end
  end

  describe "Validations" do
    subject { FactoryGirl.create(:site) }

    [:hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :badged, :plan_id, :user_attributes].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_presence_of(:user) }

    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }

    specify { Site.validators_on(:hostname).map(&:class).should == [ActiveModel::Validations::PresenceValidator, HostnameValidator, HostnameUniquenessValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should == [ExtraHostnamesValidator] }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should == [DevHostnamesValidator] }

    describe "plan" do
      context "with no plan" do
        subject { FactoryGirl.build(:new_site, plan: nil) }
        it { should_not be_valid }
        it { should have(1).error_on(:plan) }
      end

      context "with no plan but a pending_plan" do
        subject { FactoryGirl.build(:new_site, plan: nil, plan_id: @paid_plan.id) }
        its(:pending_plan) { should == @paid_plan }
        it { should be_valid }
      end
    end

    describe "hostname" do
      context "with the free plan" do
        subject { site = FactoryGirl.create(:site, plan_id: @free_plan.id); site.hostname = ''; site }
        it { should be_valid }
      end
      context "with a paid plan" do
        subject { site = FactoryGirl.create(:site, plan_id: @paid_plan.id); site.hostname = ''; site }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
      end
      context "with a pending paid plan" do
        subject { site = FactoryGirl.create(:site_pending, plan_id: @paid_plan.id); site.hostname = ''; site }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
      end
    end

    describe "credit card" do
      context "without credit card" do
        subject do
          site = FactoryGirl.build(:new_site, user: FactoryGirl.create(:user_no_cc), plan_id: @paid_plan.id)
          site.save
          site
        end
        it { should be_valid }
      end

      context "with credit card attributes given" do
        subject { FactoryGirl.build(:site, user_attributes: valid_cc_attributes, plan_id: @paid_plan.id) }
        it { should be_valid }
      end
    end

    describe "no hostnames at all" do
      context "hostnames are blank & plan is free plan" do
        subject { FactoryGirl.build(:new_site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil, plan: @free_plan) }
        it { should be_valid } # dev hostnames are set before validation
        it { should have(0).error_on(:base) }
      end

      context "hostnames are blank & plan is not free plan" do
        subject { FactoryGirl.build(:new_site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil, plan: @paid_plan) }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
        it { should have(0).error_on(:base) }
      end
    end

    describe "validates_current_password" do
      context "on a free plan" do
        subject { FactoryGirl.create(:site, plan_id: @free_plan.id) }

        it "should not validate current_password when modifying settings" do
          subject.update_attributes(hostname: "newone.com").should be_true
          subject.errors[:base].should be_empty
        end
        it "should not validate current_password when modifying plan" do
          VCR.use_cassette('ogone/visa_payment_generic') { subject.update_attributes(plan_id: @paid_plan.id).should be_true }
          subject.errors[:base].should be_empty
        end
      end

      context "on a paid plan" do
        context "in trial" do
          subject { FactoryGirl.create(:site, plan_id: @paid_plan.id) }

          describe "when updating a site in paid plan" do
            it "needs current_password" do
              subject.update_attributes(plan_id: @custom_plan.token).should be_true
              subject.errors.should be_empty
            end
          end
        end

        context "not in trial" do
          subject { FactoryGirl.create(:site_not_in_trial, plan_id: @paid_plan.id) }

          describe "when updating a site in paid plan" do
            it "needs current_password" do
              subject.update_attributes(plan_id: @custom_plan.token).should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end

            it "needs right current_password" do
              subject.update_attributes(plan_id: @custom_plan.token, user_attributes: { current_password: "wrong" }).should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end
          end

          describe "when update paid plan settings" do
            it "needs current_password" do
              subject.update_attributes(hostname: "newone.com").should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end

            it "needs right current_password" do
              subject.update_attributes(hostname: "newone.com", user_attributes: { current_password: "wrong" }).should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end

            it "don't need current_password with other errors" do
              subject.update_attributes(hostname: "", email: "").should be_false
              subject.errors[:base].should be_empty
            end
          end

          describe "when downgrade to free plan" do
            it "needs current_password" do
              subject.update_attributes(plan_id: @free_plan.id).should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end

            it "needs right current_password" do
              subject.update_attributes(plan_id: @free_plan.id, user_attributes: { :current_password => "wrong" }).should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end
          end

          describe "when archive" do
            it "needs current_password" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end

            it "needs right current_password" do
              subject.user.current_password = 'wrong'
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end
          end

          describe "when suspend" do
            it "don't need current_password" do
              subject.suspend.should be_true
              subject.errors[:base].should be_empty
            end
          end
        end
      end
    end # validates_current_password

    describe "prevent_archive_with_non_paid_invoices" do
      subject { @site.reload; @site.user.current_password = '123456'; @site }

      context "first invoice" do
        before(:all) do
          @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: nil)
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          before(:all) do
            Invoice.delete_all
            @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
          end

          it "archives the site" do
            subject.archive!.should be_true
            subject.errors[:base].should be_empty
          end
        end

        context "with a failed invoice" do
          before(:all) do
            Invoice.delete_all
            @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
          end

          it "archives the site" do
            subject.archive!.should be_true
            subject.errors[:base].should be_empty
          end
        end

        context "with a waiting invoice" do
          before(:all) do
            Invoice.delete_all
            @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
          end

          it "archives the site" do
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.not_paid_invoices_prevent_archive', :count => 1)
          end
        end
      end

      context "not first invoice" do
        before(:all) do
          @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
          before(:all) do
            Invoice.delete_all
            @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
          end

          it "doesn't archive the site" do
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.not_paid_invoices_prevent_archive', :count => 1)
          end
        end

        context "with a failed invoice" do
          before(:all) do
            Invoice.delete_all
            @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
          end

          it "doesn't archive the site" do
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.not_paid_invoices_prevent_archive', :count => 1)
          end
        end

        context "with a waiting invoice" do
          before(:all) do
            Invoice.delete_all
            @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
          end

          it "doesn't archive the site" do
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.not_paid_invoices_prevent_archive', :count => 1)
          end
        end
      end
    end

    describe "set_default_badged" do
      context "with the free plan" do
        describe "badge on" do
          subject { FactoryGirl.build(:site, plan_id: @free_plan.id, badged: true) }
          its(:badged) { should be_true }
          it { should be_valid }
        end
        describe "badge off" do
          subject { FactoryGirl.build(:site, plan_id: @free_plan.id, badged: false) }
          its(:badged) { should be_true }
          it { should be_valid }
          it { should be_valid }
        end
      end
      context "with a paid plan" do
        describe "badge on" do
          subject { FactoryGirl.build(:site, plan_id: @paid_plan.id, badged: true) }
          its(:badged) { should be_true }
          it { should be_valid }
        end
        describe "badge off" do
          subject { FactoryGirl.build(:site, plan_id: @paid_plan.id, badged: false) }
          its(:badged) { should be_false }
          it { should be_valid }
        end
      end
    end

  end # Validations

  describe "Attributes Accessors" do
    %w[hostname extra_hostnames dev_hostnames].each do |attr|
      describe "#{attr}=" do
        it "calls Hostname.clean" do
          site = FactoryGirl.build(:new_site)
          Hostname.should_receive(:clean).with("foo.com")

          site.send("#{attr}=", "foo.com")
        end
      end
    end

    describe "path=" do
      describe "sets to '' if nil is given" do
        subject { FactoryGirl.create(:site, path: nil) }

        its(:path) { should == '' }
      end
      describe "removes first and last /" do
        subject { FactoryGirl.create(:site, path: '/users/thibaud/') }

        its(:path) { should == 'users/thibaud' }
      end
      describe "downcases path" do
        subject { FactoryGirl.create(:site, path: '/Users/thibaud') }

        its(:path) { should == 'users/thibaud' }
      end
    end

    describe "plan_id=" do
      before(:all) do
        @paid_plan2        = FactoryGirl.create(:plan, name: "gold",   cycle: "month", price: 5000)
        @paid_plan_yearly  = FactoryGirl.create(:plan, name: "silver", cycle: "year",  price: 10000)
        @paid_plan_yearly2 = FactoryGirl.create(:plan, name: "gold",   cycle: "year",  price: 50000)
      end

      describe "when creating with a free plan" do
        before(:all) do
          @site = FactoryGirl.build(:new_site, plan_id: @free_plan.id)
        end
        subject { @site }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should eql @free_plan.id }
        its(:next_cycle_plan_id) { should be_nil }

        describe "should prevent new plan_id update while pending_plan_id is present" do
          before(:all) { subject.plan_id = @paid_plan.id }

          its(:plan_id)            { should be_nil }
          its(:pending_plan_id)    { should eql @free_plan.id }
          its(:next_cycle_plan_id) { should be_nil }
        end
      end

      describe "when creating a with a custom plan (token)" do
        before(:all) do
          @site = FactoryGirl.build(:new_site, plan_id: @custom_plan.token)
        end
        subject { @site }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should eql @custom_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when creating a with a custom plan (id)" do
        before(:all) do
          @site = FactoryGirl.build(:new_site, plan_id: @custom_plan.id)
        end
        subject { @site }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "upgrade" do
        describe "free =>" do
          before(:all) do
            @site = FactoryGirl.create(:new_site, plan: @free_plan)
          end

          describe "monthly" do
            before(:each) { @site.reload.plan_id = @paid_plan.id }
            subject { @site }

            its(:plan_id)            { should eql @free_plan.id }
            its(:pending_plan_id)    { should eql @paid_plan.id }
            its(:next_cycle_plan_id) { should be_nil }
          end

          describe "yearly" do
            before(:each) { @site.reload.plan_id = @paid_plan_yearly.id }
            subject { @site }

            its(:plan_id)            { should eql @free_plan.id }
            its(:pending_plan_id)    { should eql @paid_plan_yearly.id }
            its(:next_cycle_plan_id) { should be_nil }
          end

          describe "sponsored" do
            before(:each) { @site.reload.plan_id = @sponsored_plan.id }
            subject { @site }

            its(:plan_id)            { should eql @free_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end
        end

        describe "monthly =>" do
          before(:all) do
            @site = FactoryGirl.create(:new_site, plan: @paid_plan)
          end

          describe "monthly" do
            before(:each) { @site.reload.plan_id = @paid_plan2.id }
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should eql @paid_plan2.id }
            its(:next_cycle_plan_id) { should be_nil }
          end

          describe "monthly (with a next_cycle_plan)" do
            before(:each) { @site.reload.next_cycle_plan_id = @paid_plan_yearly.id; @site.plan_id = @paid_plan2.id }
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should eql @paid_plan2.id }
            its(:next_cycle_plan_id) { should be_nil }
          end

          context "with an open invoice" do
            before(:each) do
              FactoryGirl.create(:invoice, site: @site, state: 'open')
              @site.reload.plan_id = @paid_plan2.id
            end
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end

          context "with an waiting invoice" do
            before(:each) do
              FactoryGirl.create(:invoice, site: @site, state: 'waiting')
              @site.reload.plan_id = @paid_plan2.id
            end
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end

          context "with a failed invoice" do
            before(:each) do
              FactoryGirl.create(:invoice, site: @site, state: 'failed')
              @site.reload.plan_id = @paid_plan2.id
            end
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end

          describe "same monthly plan" do
            before(:each) { @site.reload.plan_id = @paid_plan.id }
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end

          describe "yearly" do
            before(:each) { @site.reload.plan_id = @paid_plan_yearly.id }
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should eql @paid_plan_yearly.id }
            its(:next_cycle_plan_id) { should be_nil }
          end

          describe "custom plan (token)" do
            before(:each) { @site.reload.plan_id = @custom_plan.token }
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should eql @custom_plan.id }
            its(:next_cycle_plan_id) { should be_nil }
          end

          describe "custom plan (id)" do
            before(:each) { @site.reload.plan_id = @custom_plan.id }
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end

          describe "sponsored" do
            before(:each) { @site.reload.plan_id = @sponsored_plan.id }
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end
        end
      end

      describe "upgrade yearly => yearly" do
        before(:all) do
          @site = FactoryGirl.build(:new_site, plan: @paid_plan_yearly)
          @site.plan_id = @paid_plan_yearly2.id
        end
        subject { @site }

        its(:plan_id)            { should eql @paid_plan_yearly.id }
        its(:pending_plan_id)    { should eql @paid_plan_yearly2.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "downgrade" do
        context "during trial" do
          describe "monthly =>" do
            before(:all) do
              @site = FactoryGirl.create(:new_site, plan: @paid_plan2)
              @site.should be_in_trial
            end

            { free: :free_plan, monthly: :paid_plan, yearly: :paid_plan_yearly }.each do |plan_name, plan|
              describe plan_name do
                before(:each) { @site.reload.plan_id = instance_variable_get("@#{plan}").id }
                subject { @site }

                its(:plan_id)            { should eql @paid_plan2.id }
                its(:pending_plan_id)    { should eql instance_variable_get("@#{plan}").id }
                its(:next_cycle_plan_id) { should be_nil }
              end
            end
          end
        end

        context "after trial" do
          context "first_paid_plan_started_at is nil" do
            before(:all) do
              @site = FactoryGirl.create(:site_not_in_trial, plan: @paid_plan2, first_paid_plan_started_at: nil)
              @site.first_paid_plan_started_at.should be_nil
              @site.should_not be_in_trial
            end

            { free: :free_plan, monthly: :paid_plan, yearly: :paid_plan_yearly }.each do |plan_name, plan|
              describe plan_name do
                before(:each) { @site.reload.plan_id = instance_variable_get("@#{plan}").id }
                subject { @site }

                its(:plan_id)            { should eql @paid_plan2.id }
                its(:pending_plan_id)    { should eql instance_variable_get("@#{plan}").id }
                its(:next_cycle_plan_id) { should be_nil }
              end
            end
          end

          context "first_paid_plan_started_at is not nil" do
            before(:all) do
              @site = FactoryGirl.create(:site_with_invoice, plan_id: @paid_plan2.id, first_paid_plan_started_at: Time.now.utc)
              @site.first_paid_plan_started_at.should be_present
              @site.should_not be_in_trial
            end

            { free: :free_plan, monthly: :paid_plan, yearly: :paid_plan_yearly }.each do |plan_name, plan|
              describe plan_name do
                before(:each) { @site.reload.plan_id = instance_variable_get("@#{plan}").id }
                subject { @site }

                its(:plan_id)            { should eql @paid_plan2.id }
                its(:pending_plan_id)    { should be_nil }
                its(:next_cycle_plan_id) { should eql instance_variable_get("@#{plan}").id }
              end
            end
          end
        end
      end
    end

  end

  describe "State Machine" do
    before(:each) { VoxcastCDN.stub(:purge) }

    describe "#suspend" do
      subject do
        site = FactoryGirl.build(:new_site)
        site.apply_pending_plan_changes
        @worker.work_off
        site
      end

      it "should clear & purge license & loader" do
        VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
        VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
        subject.suspend
        @worker.work_off
        subject.reload.loader.should_not be_present
        subject.license.should_not be_present
      end
    end

    describe "#unsuspend" do
      subject do
        site = FactoryGirl.build(:new_site)
        site.apply_pending_plan_changes
        @worker.work_off
        site
      end

      it "should reset license & loader" do
        VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
        VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
        subject.suspend
        @worker.work_off
        subject.reload.loader.should_not be_present
        subject.license.should_not be_present

        subject.unsuspend
        @worker.work_off
        subject.reload.loader.should be_present
        subject.license.should be_present
      end
    end

    describe "#archive" do
      context "from active state" do
        subject do
          site = FactoryGirl.create(:site)
          @worker.work_off
          site
        end

        it "should clear & purge license & loader and set archived_at" do
          VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
          VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.user.current_password = '123456'
          lambda { subject.archive! }.should change(Delayed::Job, :count).by(1)
          subject.reload.should be_archived
          lambda { @worker.work_off }.should change(Delayed::Job, :count).by(-1)
          subject.reload.loader.should_not be_present
          subject.license.should_not be_present
          subject.archived_at.should be_present
        end

        context "first invoice" do
          subject { @site.reload; @site.user.current_password = '123456'; @site }

          before(:all) do
            @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: nil)
            Invoice.delete_all
            @site.first_paid_plan_started_at.should be_nil
          end

          context "with an open invoice" do
            before(:all) do
              @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
            end

            it "archives the site" do
              subject.archive!.should be_true
              subject.should be_archived
              @open_invoice.reload.should be_canceled
            end
          end

          context "with a failed invoice" do
            before(:all) do
              @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
            end

            it "archives the site" do
              subject.archive!.should be_true
              subject.should be_archived
              @failed_invoice.reload.should be_canceled
            end
          end

          context "with a waiting invoice" do
            before(:all) do
              @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
            end

            it "archives the site" do
              subject.archive.should be_false
              subject.should_not be_archived
              @waiting_invoice.reload.should be_waiting
            end
          end
        end

        context "not first invoice" do
          subject { @site.reload; @site.user.current_password = '123456'; @site }
          before(:all) do
            @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: Time.now.utc)
            Invoice.delete_all
            @site.first_paid_plan_started_at.should be_present
          end

          %w[open failed waiting].each do |invoice_state|
            context "with a #{invoice_state} invoice" do
              before(:all) do
                @invoice = FactoryGirl.create(:invoice, site: @site, state: invoice_state)
              end

              it "doesn't archive the site" do
                subject.archive.should be_false
                subject.should_not be_archived
                @invoice.reload.state.should eql invoice_state
              end
            end
          end
        end

      end
    end

  end

  describe "Versioning" do
    subject { with_versioning { FactoryGirl.create(:site) } }

    it "works!" do
      with_versioning do
        old_hostname = subject.hostname
        subject.update_attributes(hostname: "bob.com", user_attributes: { 'current_password' => '123456' })
        subject.versions.last.reify.hostname.should eql old_hostname
      end
    end

    [:cdn_up_to_date, :license, :loader].each do |attr|
      it "doesn't version when :#{attr} changes" do
        with_versioning do
          expect do
            subject.update_attributes(attr => "bob.com", user_attributes: { 'current_password' => '123456' })
          end.to_not change(subject.versions, :count)
        end
      end
    end
  end # Versioning

  describe "Callbacks" do

    describe "before_validation" do
      subject { FactoryGirl.build(:new_site, dev_hostnames: nil) }

      describe "#set_user_attributes"  do
        subject { FactoryGirl.create(:user, first_name: "Bob") }

        it "should set only current_password" do
          subject.first_name.should eql "Bob"
          site = FactoryGirl.create(:site, user: subject, plan_id: @paid_plan.id)
          site.update_attributes(user_attributes: { first_name: "John", 'current_password' => '123456' })
          site.user.first_name.should eql "Bob"
          site.user.current_password.should eql "123456"
        end
      end

      describe "#set_default_dev_hostnames" do
        specify do
          subject.dev_hostnames.should be_nil
          subject.should be_valid
          subject.dev_hostnames.should eql Site::DEFAULT_DEV_DOMAINS
        end
      end

    end

    describe "before_save" do
      subject { FactoryGirl.create(:site_with_invoice, first_paid_plan_started_at: Time.now.utc) }

      describe "#clear_alerts_sent_at" do
        specify do
          subject.should_receive(:clear_alerts_sent_at)
          subject.save
        end
      end

      describe "#pend_plan_changes" do
        context "when pending_plan_id has changed" do
          it "should call #pend_plan_changes" do
            subject.reload
            subject.plan_id = @paid_plan.id
            VCR.use_cassette('ogone/visa_payment_generic') { subject.save_without_password_validation }
            subject.pending_plan_id.should == @paid_plan.id
            subject.reload # apply_pending_plan_changes called
            subject.plan_id.should == @paid_plan.id
            subject.pending_plan_id.should be_nil
          end
        end

        context "when pending_plan_id doesn't change" do
          it "should not call #pend_plan_changes" do
            subject.hostname = 'test.com'
            subject.save_without_password_validation
            subject.pending_plan_id.should be_nil
          end
        end
      end
    end # before_save

    describe "after_save" do
      subject { FactoryGirl.create(:site) }

      describe "#create_and_charge_invoice" do
        it "should call #create_and_charge_invoice" do
          subject.should_receive(:create_and_charge_invoice)
          subject.save!
        end
      end
    end

    describe "after_create" do
      it "should delay update_ranks" do
        expect { FactoryGirl.create(:site) }.to change(Delayed::Job.where { handler =~ "%update_ranks%" }, :count).by(1)
      end

      it "should update ranks" do
        Timecop.travel(10.minutes.ago) { @site = FactoryGirl.create(:site, hostname: 'sublimevideo.net') }
        VCR.use_cassette('sites/ranks') { @worker.work_off }
        @site.reload
        @site.google_rank.should == 6
        @site.alexa_rank.should == 127373
      end
    end # after_create

  end # Callbacks

  describe "Instance Methods" do

    describe "#clear_alerts_sent_at" do
      subject { FactoryGirl.create(:site_with_invoice, plan_id: @paid_plan.id) }

      it "should clear *_alert_sent_at dates" do
        subject.touch(:plan_player_hits_reached_notification_sent_at)
        subject.plan_player_hits_reached_notification_sent_at.should be_present
        VCR.use_cassette('ogone/visa_payment_generic') do
          subject.update_attributes(plan_id: @custom_plan.token, user_attributes: { 'current_password' => '123456' })
        end
        subject.apply_pending_plan_changes
        subject.plan_player_hits_reached_notification_sent_at.should be_nil
      end
    end

    describe "#without_password_validation" do
      subject { FactoryGirl.create(:site_not_in_trial, hostname: "rymai.com") }

      it "should ask password when not calling this method" do
        subject.hostname.should == "rymai.com"
        subject.hostname = "remy.com"
        subject.save
        subject.should_not be_valid
        subject.should have(1).error_on(:base)
      end

      it "should not ask password when calling this method" do
        subject.hostname.should == "rymai.com"
        subject.hostname = "remy.com"
        subject.without_password_validation { subject.save }
        subject.should have(0).error_on(:base)
        subject.reload.hostname.should == "remy.com"
      end

      it "should return the result of the given block" do
        subject.without_password_validation { "foo" }.should == "foo"
      end
    end

    describe "#save_without_password_validation" do
      subject { FactoryGirl.create(:site_not_in_trial, hostname: "rymai.com") }

      it "should ask password when not calling this method" do
        subject.hostname.should == "rymai.com"
        subject.hostname = "remy.com"
        subject.save
        subject.should_not be_valid
        subject.should have(1).error_on(:base)
      end

      it "should not ask password when calling this method" do
        subject.hostname.should == "rymai.com"
        subject.hostname = "remy.com"
        subject.save_without_password_validation
        subject.should have(0).error_on(:base)
        subject.reload.hostname.should == "remy.com"
      end

      it "should return the result of the given block" do
        subject.without_password_validation { "foo" }.should == "foo"
      end
    end

    describe "#sponsor!" do
      describe "sponsor a site with a next plan" do
        before(:all) { Timecop.travel(1.day.ago) { @site = FactoryGirl.create(:site_not_in_trial) } }
        subject { @site.reload; @site.next_cycle_plan_id = @free_plan.id; @site }

        it "changes the plan to sponsored plan" do
          subject.next_cycle_plan_id.should be_present
          subject.pending_plan_id.should be_nil
          subject.plan_started_at.should be_present
          initial_plan_started_at = subject.plan_started_at
          subject.plan_cycle_started_at.should be_present
          subject.plan_cycle_ended_at.should be_present

          subject.sponsor!
          subject.reload

          subject.should be_in_sponsored_plan
          subject.next_cycle_plan_id.should be_nil
          subject.pending_plan_id.should be_nil
          subject.plan_started_at.should be_present
          subject.plan_started_at.should == initial_plan_started_at # same as an upgrade
          subject.plan_cycle_started_at.should be_nil
          subject.plan_cycle_ended_at.should be_nil
        end
      end
    end

    describe "#hostname_with_path_needed & #need_path?" do
      context "with web.me.com hostname" do
        subject { FactoryGirl.build(:site, hostname: 'web.me.com') }
        its(:need_path?)                { should be_true }
        its(:hostname_with_path_needed) { should == 'web.me.com' }
      end
      context "with homepage.mac.com, web.me.com extra hostnames" do
        subject { FactoryGirl.build(:site, extra_hostnames: 'homepage.mac.com, web.me.com') }
        its(:need_path?)                { should be_true }
        its(:hostname_with_path_needed) { should == 'web.me.com' }
      end
      context "with web.me.com hostname & path" do
        subject { FactoryGirl.build(:site, hostname: 'web.me.com', path: 'users/thibaud') }
        its(:need_path?)                { should be_false }
        its(:hostname_with_path_needed) { should be_nil }
      end
      context "with nothing special" do
        subject { FactoryGirl.build(:site) }
        its(:need_path?)                { should be_false }
        its(:hostname_with_path_needed) { should be_nil }
      end
    end

    describe "#hostname_with_subdomain_needed & #need_subdomain?" do
      context "with tumblr.com hostname" do
        subject { FactoryGirl.build(:site, wildcard: true, hostname: 'tumblr.com') }
        its(:need_subdomain?)                { should be_true }
        its(:hostname_with_subdomain_needed) { should == 'tumblr.com' }
      end
      context "with tumblr.com extra hostnames" do
        subject { FactoryGirl.build(:site, wildcard: true, extra_hostnames: 'web.mac.com, tumblr.com') }
        its(:need_subdomain?)                { should be_true }
        its(:hostname_with_subdomain_needed) { should == 'tumblr.com' }
      end
      context "with wildcard only" do
        subject { FactoryGirl.build(:site, wildcard: true) }
        its(:need_subdomain?)                { should be_false }
        its(:hostname_with_subdomain_needed) { should be_nil }
      end
      context "without wildcard" do
        subject { FactoryGirl.build(:site, hostname: 'tumblr.com') }
        its(:need_subdomain?)                { should be_false }
        its(:hostname_with_subdomain_needed) { should be_nil }
      end
    end

    describe "#plan_month_cycle_started_at & #plan_month_cycle_ended_at" do
      before(:all) { @site = FactoryGirl.create(:site) }

      context "with free plan" do
        before(:all) do
          @site.plan.cycle            = "none"
          @site.plan_started_at       = Time.utc(2011,1,10).midnight
          @site.plan_cycle_started_at = nil
          @site.plan_cycle_ended_at   = nil
          Timecop.travel(Time.utc(2011,4,1))
        end
        after(:all) { Timecop.return }
        subject { @site }

        its(:plan_month_cycle_started_at) { should == Time.utc(2011,3,2).midnight }
        its(:plan_month_cycle_ended_at)   { should == Time.utc(2011,4,1).end_of_day }
      end

      context "with monthly plan" do
        before(:all) do
          @site.plan.cycle            = "month"
          @site.plan_cycle_started_at = Time.utc(2011,1,1).midnight
          @site.plan_cycle_ended_at   = Time.utc(2011,1,31).end_of_day
        end
        subject { @site }

        its(:plan_month_cycle_started_at) { should == Time.utc(2011,1,1).midnight }
        its(:plan_month_cycle_ended_at)   { should == Time.utc(2011,1,31).end_of_day }
      end

      context "with yearly plan" do
        before(:all) do
          @site.plan.cycle            = "year"
          @site.plan_cycle_started_at = Time.utc(2011,1,1).midnight
          @site.plan_cycle_ended_at   = Time.utc(2011,12,31).end_of_day
          Timecop.travel(Time.utc(2011,6,10))
        end
        after(:all) { Timecop.return }
        subject { @site }

        its(:plan_month_cycle_started_at) { should == Time.utc(2011,6,1).midnight }
        its(:plan_month_cycle_ended_at)   { should == Time.utc(2011,6,30).end_of_day }
      end

      context "with yearly plan (other date)" do
        before(:all) do
          @site.plan.cycle            = "year"
          @site.plan_cycle_started_at = Time.utc(2011,2,28).midnight
          @site.plan_cycle_ended_at   = Time.utc(2012,2,27).end_of_day
          Timecop.travel(Time.utc(2012,2,10))
        end
        after(:all) { Timecop.return }
        subject { @site }

        its(:plan_month_cycle_started_at) { should == Time.utc(2012,1,28).midnight }
        its(:plan_month_cycle_ended_at)   { should == Time.utc(2012,2,27).end_of_day }
      end
    end

    describe "#recommended_plan" do
      before(:all) do
        Plan.delete_all
        silver = FactoryGirl.create(:plan, name: "silver", player_hits: 200_000)
        @gold_plan = FactoryGirl.create(:plan, name: "gold", player_hits: 1_000_000)
        @site = FactoryGirl.create(:site, plan_id: silver.id)
      end
      subject { @site }

      context "with no usage" do
        its(:recommended_plan_name) { should be_nil }
      end

      context "with less than 5 days of usage" do
        before(:each) do
          @site.unmemoize_all
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 1000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 1000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 1000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 1000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 0)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 6.days.ago, main_player_hits: 0)
        end

        its(:recommended_plan_name) { should be_nil }
      end

      context "with less than 5 days of usage (but with 0 between)" do
        before(:each) do
          @site.unmemoize_all
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 30_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 30_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 0)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 30_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 30_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 6.days.ago, main_player_hits: 0)
        end

        its(:recommended_plan_name) { should eql "gold" }
      end

      context "with regular usage and player_hits smaller than silver" do
        before(:each) do
          @site.unmemoize_all
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 50)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 50)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 50)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 50)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 50)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 6.days.ago, main_player_hits: 50)
        end

        its(:recommended_plan_name) { should be_nil }
      end

      context "with regular usage and player_hits between silver and gold" do
        before(:each) do
          @site.unmemoize_all
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 10_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 10_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 10_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 10_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 10_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 6.days.ago, main_player_hits: 10_000)
        end

        its(:recommended_plan_name) { should eql "gold" }
      end

      context "with non regular usage and lower than player_hits but greather than average player_hits" do
        before(:each) do
          @site.unmemoize_all
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 12_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 12_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 12_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 12_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 1_000)
        end

        its(:recommended_plan_name) { should eql "gold" }
      end

      context "with too much player_hits" do
        before(:each) do
          @site.unmemoize_all
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 500_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 500_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 500_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 500_000)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 500_000)
        end

        its(:recommended_plan_name) { should eql "custom" }
      end

      context "with recommended plan lower than current plan" do
        before(:each) do
          @site.unmemoize_all
          @site.plan = @gold_plan
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 500)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 500)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 500)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 500)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 500)
        end

        its(:recommended_plan_name) { should be_nil }
      end
    end

    describe "#archivable?" do
      subject { @site.reload }

      context "first invoice" do
        before(:all) do
          Invoice.delete_all
          @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: nil)
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
          end

          it { should be_archivable }
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
          end

          it { should be_archivable }
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end

      context "not first invoice" do
        before(:all) do
          Invoice.delete_all
          @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
          end

          it { should_not be_archivable }
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
          end

          it { should_not be_archivable }
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end
    end # #archivable?

  end # Instance Methods

end



# == Schema Information
#
# Table name: sites
#
#  id                                            :integer         not null, primary key
#  user_id                                       :integer
#  hostname                                      :string(255)
#  dev_hostnames                                 :string(255)
#  token                                         :string(255)
#  license                                       :string(255)
#  loader                                        :string(255)
#  state                                         :string(255)
#  archived_at                                   :datetime
#  created_at                                    :datetime
#  updated_at                                    :datetime
#  player_mode                                   :string(255)     default("stable")
#  google_rank                                   :integer
#  alexa_rank                                    :integer
#  path                                          :string(255)
#  wildcard                                      :boolean
#  extra_hostnames                               :string(255)
#  plan_id                                       :integer
#  pending_plan_id                               :integer
#  next_cycle_plan_id                            :integer
#  cdn_up_to_date                                :boolean         default(FALSE)
#  first_paid_plan_started_at                    :datetime
#  plan_started_at                               :datetime
#  plan_cycle_started_at                         :datetime
#  plan_cycle_ended_at                           :datetime
#  pending_plan_started_at                       :datetime
#  pending_plan_cycle_started_at                 :datetime
#  pending_plan_cycle_ended_at                   :datetime
#  plan_player_hits_reached_notification_sent_at :datetime
#  first_plan_upgrade_required_alert_sent_at     :datetime
#  refunded_at                                   :datetime
#  last_30_days_main_player_hits_total_count     :integer         default(0)
#  last_30_days_extra_player_hits_total_count    :integer         default(0)
#  last_30_days_dev_player_hits_total_count      :integer         default(0)
#  trial_started_at                              :datetime
#  badged                                        :boolean         default(TRUE)
#
# Indexes
#
#  index_sites_on_created_at                                  (created_at)
#  index_sites_on_hostname                                    (hostname)
#  index_sites_on_last_30_days_dev_player_hits_total_count    (last_30_days_dev_player_hits_total_count)
#  index_sites_on_last_30_days_extra_player_hits_total_count  (last_30_days_extra_player_hits_total_count)
#  index_sites_on_last_30_days_main_player_hits_total_count   (last_30_days_main_player_hits_total_count)
#  index_sites_on_plan_id                                     (plan_id)
#  index_sites_on_user_id                                     (user_id)
#

