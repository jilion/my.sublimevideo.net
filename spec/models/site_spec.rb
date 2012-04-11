# coding: utf-8
require 'spec_helper'

describe Site do

  context "Factory" do
    before(:all) { @site = create(:site) }
    subject { @site.reload }

    its(:user)                                    { should be_present }
    its(:plan)                                    { should be_present }
    its(:pending_plan)                            { should be_nil }
    its(:hostname)                                { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)                           { should eql "127.0.0.1, localhost" }
    its(:extra_hostnames)                         { should be_nil }
    its(:path)                                    { should be_nil }
    its(:wildcard)                                { should be_false }
    its(:badged)                                  { should be_false }
    its(:token)                                   { should =~ /^[a-z0-9]{8}$/ }
    its(:license)                                 { should_not be_present }
    its(:loader)                                  { should_not be_present }
    its(:player_mode)                             { should eql "stable" }
    its(:plan_started_at)                         { should eql Time.now.utc.midnight }
    its(:plan_cycle_started_at)                   { should be_nil }
    its(:plan_cycle_ended_at)                     { should be_nil }
    its(:pending_plan_started_at)                 { should be_nil }
    its(:pending_plan_cycle_started_at)           { should be_nil }
    its(:pending_plan_cycle_ended_at)             { should be_nil }
    its(:next_cycle_plan_id)                      { should be_nil }
    its(:last_30_days_main_video_views)           { should eq 0 }
    its(:last_30_days_extra_video_views)          { should eq 0 }
    its(:last_30_days_dev_video_views)            { should eq 0 }
    its(:last_30_days_invalid_video_views)        { should eq 0 }
    its(:last_30_days_embed_video_views)          { should eq 0 }
    its(:last_30_days_billable_video_views_array) { should have(30).items }

    it { should be_active } # initial state
    it { should_not be_in_free_plan }
    it { should be_valid }
  end

  describe "Associations" do
    before(:all) { @site = create(:site) }
    subject { @site }

    it { should belong_to :user }
    it { should belong_to :plan }
    it { should have_many :invoices }

    describe "last_invoice" do
      subject { create(:site_with_invoice, plan_id: @paid_plan.id) }

      it "should return the last paid invoice" do
        subject.last_invoice.should eq subject.invoices.last
      end
    end
  end

  describe "Validations" do
    subject { create(:site) }

    [:hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :badged, :plan_id, :user_attributes].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_presence_of(:user) }
    it { should ensure_length_of(:extra_hostnames).is_at_most(255) }
    it { should ensure_length_of(:dev_hostnames).is_at_most(255) }

    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }

    specify { Site.validators_on(:hostname).map(&:class).should eq [ActiveModel::Validations::PresenceValidator, HostnameValidator, HostnameUniquenessValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should include ExtraHostnamesValidator }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should include DevHostnamesValidator }

    describe "plan" do
      context "with no plan" do
        subject { build(:new_site, plan_id: nil) }
        it { should_not be_valid }
        it { should have(1).error_on(:plan) }
      end

      context "with no plan but a pending_plan" do
        subject { build(:new_site, plan_id: @paid_plan.id) }
        its(:pending_plan) { should eq @paid_plan }
        it { should be_valid }
      end
    end

    describe "hostname" do
      context "with the free plan" do
        subject { site = create(:site, plan_id: @free_plan.id); site.hostname = ''; site }
        it { should be_valid }
      end
      context "with a paid plan" do
        subject { site = create(:site, plan_id: @paid_plan.id); site.hostname = ''; site }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
      end
      context "with a pending paid plan" do
        subject { site = create(:site_pending, plan_id: @paid_plan.id); site.hostname = ''; site }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
      end
    end

    describe "credit card" do
      context "without credit card" do
        subject do
          site = build(:new_site, user: create(:user_no_cc), plan_id: @paid_plan.id)
          site.save
          site
        end
        it { should be_valid }
      end

      context "with credit card attributes given" do
        subject { build(:site, user_attributes: valid_cc_attributes, plan_id: @paid_plan.id) }
        it { should be_valid }
      end
    end

    describe "no hostnames at all" do
      context "hostnames are blank & plan is free plan" do
        subject { build(:new_site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil, plan: @free_plan) }
        it { should be_valid } # dev hostnames are set before validation
        it { should have(0).error_on(:base) }
      end

      context "hostnames are blank & plan is not free plan" do
        subject { build(:new_site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil, plan: @paid_plan) }
        it { should_not be_valid }
        it { should have(1).error_on(:hostname) }
        it { should have(0).error_on(:base) }
      end
    end

    describe "validates_current_password" do
      context "on a free plan" do
        subject { create(:site, plan_id: @free_plan.id) }

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
          subject { create(:site, plan_id: @paid_plan.id) }

          describe "when updating a site in paid plan" do
            it "needs current_password" do
              subject.update_attributes(plan_id: @custom_plan.token).should be_true
              subject.errors.should be_empty
            end
          end
        end

        context "not in trial" do
          subject { create(:site_not_in_trial, plan_id: @paid_plan.id) }

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
              subject.update_attributes(hostname: "", dev_hostnames: "").should be_false
              subject.errors[:base].should be_empty
            end
          end

          describe "when downgrade to free plan" do
            it "needs current_password" do
              subject.update_attributes(plan_id: @free_plan.id).should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
            end

            it "needs right current_password" do
              subject.update_attributes(plan_id: @free_plan.id, user_attributes: { current_password: "wrong" }).should be_false
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
      subject { @site }
      before { Invoice.delete_all }

      context "first invoice" do
        before do
          @site = create(:new_site, first_paid_plan_started_at: nil)
          @site.first_paid_plan_started_at.should be_nil
          @site.user.current_password = '123456'
        end

        %w[open failed].each do |invoice_state|
          context "with an #{invoice_state} invoice" do
            before { create(:invoice, site: @site, state: invoice_state) }

            it "archives the site" do
              subject.archive.should be_true
              subject.errors[:base].should be_empty
            end
          end
        end

        context "with a waiting invoice" do
          it "archives the site" do
            create(:invoice, site: @site, state: 'waiting')
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.not_paid_invoices_prevent_archive', count: 1)
          end
        end
      end

      context "not first invoice" do
        before do
          @site = create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.first_paid_plan_started_at.should be_present
          @site.user.current_password = '123456'
        end

        %w[open waiting failed].each do |invoice_state|
          context "with an #{invoice_state} invoice" do
            before { create(:invoice, site: @site, state: invoice_state) }

            it "doesn't archive the site" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.not_paid_invoices_prevent_archive', count: 1)
            end
          end
        end
      end
    end

    describe "set_default_badged" do
      context "with the free plan" do
        describe "badge on" do
          subject { build(:site, plan_id: @free_plan.id, badged: true) }
          its(:badged) { should be_true }
          it { should be_valid }
        end
        describe "badge off" do
          subject { build(:site, plan_id: @free_plan.id, badged: false) }
          its(:badged) { should be_true }
          it { should be_valid }
          it { should be_valid }
        end
      end
      context "with a paid plan" do
        describe "badge on" do
          subject { build(:site, plan_id: @paid_plan.id, badged: true) }
          its(:badged) { should be_true }
          it { should be_valid }
        end
        describe "badge off" do
          subject { build(:site, plan_id: @paid_plan.id, badged: false) }
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
          site = build(:new_site)
          Hostname.should_receive(:clean).with("foo.com")

          site.send("#{attr}=", "foo.com")
        end
      end
    end

    describe "#hostname_or_token" do
      context "site with a hostname" do
        subject { create(:site, hostname: 'rymai.me') }

        specify { subject.hostname_or_token.should eql 'rymai.me' }
      end

      context "site without a hostname" do
        subject { create(:site, plan_id: @free_plan.id, hostname: '') }

        specify { subject.hostname_or_token.should eql "##{subject.token}" }
      end
    end

    describe "path=" do
      describe "sets to '' if nil is given" do
        subject { create(:site, path: nil) }

        its(:path) { should eq '' }
      end
      describe "removes first and last /" do
        subject { create(:site, path: '/users/thibaud/') }

        its(:path) { should eq 'users/thibaud' }
      end
      describe "downcases path" do
        subject { create(:site, path: '/Users/thibaud') }

        its(:path) { should eq 'users/thibaud' }
      end
    end

    describe "plan_id=" do
      before(:each) do
        @paid_plan2        = create(:plan, name: "premium",   cycle: "month", price: 5000)
        @paid_plan_yearly  = create(:plan, name: "plus", cycle: "year",  price: 10000)
        @paid_plan_yearly2 = create(:plan, name: "premium",   cycle: "year",  price: 50000)
      end

      describe "when creating with a free plan" do
        subject { build(:new_site, plan_id: @free_plan.id) }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should eql @free_plan.id }
        its(:next_cycle_plan_id) { should be_nil }

        describe "should prevent new plan_id update while pending_plan_id is present" do
          before(:each) { subject.plan_id = @paid_plan.id }

          its(:plan_id)            { should be_nil }
          its(:pending_plan_id)    { should eql @free_plan.id }
          its(:next_cycle_plan_id) { should be_nil }
        end
      end

      describe "when creating a with a custom plan (token)" do
        subject { build(:new_site, plan_id: @custom_plan.token) }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should eql @custom_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "when creating a with a custom plan (id)" do
        subject { build(:new_site, plan_id: @custom_plan.id) }

        its(:plan_id)            { should be_nil }
        its(:pending_plan_id)    { should be_nil }
        its(:next_cycle_plan_id) { should be_nil }
      end

      describe "upgrade" do
        describe "free =>" do
          before(:each) do
            @site = create(:new_site, plan: @free_plan)
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
          before(:each) do
            @site = create(:new_site, plan: @paid_plan)
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
              create(:invoice, site: @site, state: 'open')
              @site.reload.plan_id = @paid_plan2.id
            end
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end

          context "with an waiting invoice" do
            before(:each) do
              create(:invoice, site: @site, state: 'waiting')
              @site.reload.plan_id = @paid_plan2.id
            end
            subject { @site }

            its(:plan_id)            { should eql @paid_plan.id }
            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end

          context "with a failed invoice" do
            before(:each) do
              create(:invoice, site: @site, state: 'failed')
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
        before(:each) do
          @site = build(:new_site, plan: @paid_plan_yearly)
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
            before(:each) do
              @site = create(:new_site, plan: @paid_plan2)
              @site.should be_trial_not_started_or_in_trial
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
            before(:each) do
              @site = create(:site_not_in_trial, plan: @paid_plan2, first_paid_plan_started_at: nil)
              @site.first_paid_plan_started_at.should be_nil
              @site.should_not be_trial_not_started_or_in_trial
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
            before(:each) do
              @site = create(:site_with_invoice, plan_id: @paid_plan2.id, first_paid_plan_started_at: Time.now.utc)
              @site.first_paid_plan_started_at.should be_present
              @site.should_not be_trial_not_started_or_in_trial
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
        site = build(:new_site)
        site.apply_pending_attributes
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
        site = build(:new_site)
        site.apply_pending_attributes
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
          site = create(:site)
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
          before do
            @site = create(:new_site, first_paid_plan_started_at: nil)
            @site.first_paid_plan_started_at.should be_nil
            @site.user.current_password = '123456'
            Invoice.delete_all
          end
          subject { @site }

          context "with an open invoice" do
            it "archives the site" do
              create(:invoice, site: @site, state: 'open')
              subject.archive.should be_true
            end
          end

          context "with a failed invoice" do
            it "archives the site" do
              create(:invoice, site: @site, state: 'failed')
              subject.archive.should be_true
            end
          end

          context "with a waiting invoice" do
            it "archives the site" do
              create(:invoice, site: @site, state: 'waiting')
              subject.archive.should be_false
            end
          end
        end

        context "not first invoice" do
          subject { @site }
          before do
            @site = create(:new_site, first_paid_plan_started_at: Time.now.utc)
            @site.first_paid_plan_started_at.should be_present
            @site.user.current_password = '123456'
            Invoice.delete_all
          end

          %w[open failed waiting].each do |invoice_state|
            context "with a #{invoice_state} invoice" do
              it "doesn't archive the site" do
                create(:invoice, site: @site, state: invoice_state)
                subject.archive.should be_false
              end
            end
          end
        end

      end
    end

  end

  describe "Versioning" do
    subject { with_versioning { create(:site) } }

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
            subject.send("#{attr}=", "bob.com")
            subject.save
          end.to_not change(subject.versions, :count)
        end
      end
    end
  end # Versioning

  describe "Callbacks" do

    describe "before_validation" do
      subject { build(:new_site, dev_hostnames: nil) }

      describe "#set_user_attributes"  do
        subject { create(:user, name: "Bob") }

        it "sets only current_password" do
          subject.name.should eql "Bob"
          site = create(:site, user: subject, plan_id: @paid_plan.id)
          site.update_attributes(user_attributes: { name: "John", 'current_password' => '123456' })
          site.user.name.should eql "Bob"
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
      subject { create(:site_with_invoice, first_paid_plan_started_at: Time.now.utc) }

      describe "#clear_alerts_sent_at" do
        specify do
          subject.should_receive(:clear_alerts_sent_at)
          subject.save
        end
      end

      describe "#prepare_pending_attributes" do
        context "when pending_plan_id has changed" do
          it "calls #prepare_pending_attributes" do
            subject.reload
            subject.plan_id = @paid_plan.id
            VCR.use_cassette('ogone/visa_payment_generic') { subject.save_skip_pwd }
            subject.pending_plan_id.should eq @paid_plan.id
            subject.reload # apply_pending_attributes called
            subject.plan_id.should eq @paid_plan.id
            subject.pending_plan_id.should be_nil
          end
        end

        context "when pending_plan_id doesn't change" do
          it "doesn't call #prepare_pending_attributes" do
            subject.hostname = 'test.com'
            subject.save_skip_pwd
            subject.pending_plan_id.should be_nil
          end
        end
      end
    end # before_save

    describe "after_save" do
      subject { create(:site) }

      describe "#create_and_charge_invoice" do
        it "calls #create_and_charge_invoice" do
          subject.should_receive(:create_and_charge_invoice)
          subject.save!
        end
      end

      describe "#send_trial_started_email" do
        context "new site" do
          it "calls #send_trial_started_email" do
            site = build(:new_site)
            site.should_receive(:send_trial_started_email)
            site.save!
          end
        end

        context "persisted site" do
          context "trial never started before" do
            it "calls #send_trial_started_email" do
              site = create(:site, plan_id: @free_plan.id)
              site.should_receive(:send_trial_started_email)
              site.plan_id = @paid_plan.id
              site.save!
            end
          end

          context "trial already started" do
            it "doesn't call #send_trial_started_email" do
              site = create(:site)
              site.should_not_receive(:send_trial_started_email)
              site.trial_started_at = Time.now.utc
              site.save!
            end
          end
        end
      end
    end

    describe "after_create" do
      before do
        CampaignMonitor.stub(:subscriber)
        VoxcastCDN.stub(:purge)
        Pusher.stub(:[])
      end

      it "delays update_ranks" do
        expect { create(:site) }.to change(Delayed::Job.where { handler =~ "%update_ranks%" }, :count).by(1)
      end

      context "site has a hostname" do
        it "updates ranks" do
          Timecop.travel(10.minutes.ago) { @site = create(:site, hostname: 'sublimevideo.net') }
          VCR.use_cassette('sites/ranks') { @worker.work_off }
          @site.reload
          @site.google_rank.should eq 6
          @site.alexa_rank.should eq 91386
        end
      end

      context "site has blank hostname" do
        it "updates ranks" do
          Timecop.travel(10.minutes.ago) { @site = create(:site, hostname: '', plan_id: @free_plan.id) }
          VCR.use_cassette('sites/ranks') { @worker.work_off }
          @site.reload
          @site.google_rank.should eq 0
          @site.alexa_rank.should eq 0
        end
      end

      context "site has no hostname" do
        it "updates ranks" do
          Timecop.travel(10.minutes.ago) { @site = create(:site, hostname: nil, plan_id: @free_plan.id) }
          VCR.use_cassette('sites/ranks') { @worker.work_off }
          @site.reload
          @site.google_rank.should eq 0
          @site.alexa_rank.should eq 0
        end
      end

    end # after_create

  end # Callbacks

  describe "Instance Methods" do

    describe "#clear_alerts_sent_at" do
      subject { create(:site_with_invoice, plan_id: @paid_plan.id) }

      it "should clear *_alert_sent_at dates" do
        subject.touch(:overusage_notification_sent_at)
        subject.overusage_notification_sent_at.should be_present
        VCR.use_cassette('ogone/visa_payment_generic') do
          subject.update_attributes(plan_id: @custom_plan.token, user_attributes: { 'current_password' => '123456' })
        end
        subject.apply_pending_attributes
        subject.overusage_notification_sent_at.should be_nil
      end
    end

    describe "#skip_pwd" do
      subject { create(:site_not_in_trial, hostname: "rymai.com") }

      it "should ask password when not calling this method" do
        subject.hostname.should eq "rymai.com"
        subject.hostname = "remy.com"
        subject.save
        subject.should_not be_valid
        subject.should have(1).error_on(:base)
      end

      it "should not ask password when calling this method" do
        subject.hostname.should eq "rymai.com"
        subject.hostname = "remy.com"
        subject.skip_pwd { subject.save }
        subject.should have(0).error_on(:base)
        subject.reload.hostname.should eq "remy.com"
      end

      it "should return the result of the given block" do
        subject.skip_pwd { "foo" }.should eq "foo"
      end
    end

    describe "#save_skip_pwd" do
      subject { create(:site_not_in_trial, hostname: "rymai.com") }

      it "should ask password when not calling this method" do
        subject.hostname.should eq "rymai.com"
        subject.hostname = "remy.com"
        subject.save
        subject.should_not be_valid
        subject.should have(1).error_on(:base)
      end

      it "should not ask password when calling this method" do
        subject.hostname.should eq "rymai.com"
        subject.hostname = "remy.com"
        subject.save_skip_pwd
        subject.should have(0).error_on(:base)
        subject.reload.hostname.should eq "remy.com"
      end

      it "should return the result of the given block" do
        subject.skip_pwd { "foo" }.should eq "foo"
      end
    end

    describe "#sponsor!" do
      describe "sponsor a site with a next plan" do
        subject do
          site = create(:site_not_in_trial)
          site.next_cycle_plan_id = @free_plan.id
          site
        end

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
          subject.plan_started_at.should eq initial_plan_started_at # same as an upgrade
          subject.plan_cycle_started_at.should be_nil
          subject.plan_cycle_ended_at.should be_nil
        end
      end
    end

    describe "#hostname_with_path_needed & #need_path?" do
      context "with web.me.com hostname" do
        subject { build(:site, hostname: 'web.me.com') }
        its(:need_path?)                { should be_true }
        its(:hostname_with_path_needed) { should eq 'web.me.com' }
      end
      context "with homepage.mac.com, web.me.com extra hostnames" do
        subject { build(:site, extra_hostnames: 'homepage.mac.com, web.me.com') }
        its(:need_path?)                { should be_true }
        its(:hostname_with_path_needed) { should eq 'web.me.com' }
      end
      context "with web.me.com hostname & path" do
        subject { build(:site, hostname: 'web.me.com', path: 'users/thibaud') }
        its(:need_path?)                { should be_false }
        its(:hostname_with_path_needed) { should be_nil }
      end
      context "with nothing special" do
        subject { build(:site) }
        its(:need_path?)                { should be_false }
        its(:hostname_with_path_needed) { should be_nil }
      end
    end

    describe "#hostname_with_subdomain_needed & #need_subdomain?" do
      context "with tumblr.com hostname" do
        subject { build(:site, wildcard: true, hostname: 'tumblr.com') }
        its(:need_subdomain?)                { should be_true }
        its(:hostname_with_subdomain_needed) { should eq 'tumblr.com' }
      end
      context "with tumblr.com extra hostnames" do
        subject { build(:site, wildcard: true, extra_hostnames: 'web.mac.com, tumblr.com') }
        its(:need_subdomain?)                { should be_true }
        its(:hostname_with_subdomain_needed) { should eq 'tumblr.com' }
      end
      context "with wildcard only" do
        subject { build(:site, wildcard: true) }
        its(:need_subdomain?)                { should be_false }
        its(:hostname_with_subdomain_needed) { should be_nil }
      end
      context "without wildcard" do
        subject { build(:site, hostname: 'tumblr.com') }
        its(:need_subdomain?)                { should be_false }
        its(:hostname_with_subdomain_needed) { should be_nil }
      end
    end

    describe "#recommended_plan" do
      before(:each) do
        Plan.delete_all
        @plus_plan = create(:plan, name: "plus", video_views: 200_000)
        @premium_plan = create(:plan, name: "premium", video_views: 1_000_000)
        @site = create(:site, plan_id: @plus_plan.id)
      end
      subject { @site }

      context "with no usage" do
        its(:recommended_plan_name) { should be_nil }
      end

      context "with less than 5 days of usage" do
        before(:each) do
          @site.unmemoize_all
          create(:site_day_stat, t: @site.token, d: 1.day.ago.midnight, vv: { m: 1000 })
          create(:site_day_stat, t: @site.token, d: 2.day.ago.midnight, vv: { m: 1000 })
          create(:site_day_stat, t: @site.token, d: 3.day.ago.midnight, vv: { m: 1000 })
          create(:site_day_stat, t: @site.token, d: 4.day.ago.midnight, vv: { m: 1000 })
          create(:site_day_stat, t: @site.token, d: 5.day.ago.midnight, vv: { m: 0 })
          create(:site_day_stat, t: @site.token, d: 6.day.ago.midnight, vv: { m: 0 })
        end

        its(:recommended_plan_name) { should be_nil }
      end

      context "with less than 5 days of usage (but with 0 between)" do
        before(:each) do
          @site.unmemoize_all
          create(:site_day_stat, t: @site.token, d: 1.day.ago.midnight, vv: { m: 30_000 })
          create(:site_day_stat, t: @site.token, d: 2.day.ago.midnight, vv: { m: 30_000 })
          create(:site_day_stat, t: @site.token, d: 3.day.ago.midnight, vv: { m: 0 })
          create(:site_day_stat, t: @site.token, d: 4.day.ago.midnight, vv: { m: 30_000 })
          create(:site_day_stat, t: @site.token, d: 5.day.ago.midnight, vv: { m: 30_000 })
          create(:site_day_stat, t: @site.token, d: 6.day.ago.midnight, vv: { m: 0 })
        end

        its(:recommended_plan_name) { should eql "premium" }
      end

      context "with regular usage and video_views smaller than plus" do
        before(:each) do
          @site.unmemoize_all
          create(:site_day_stat, t: @site.token, d: 1.day.ago.midnight, vv: { m: 50 })
          create(:site_day_stat, t: @site.token, d: 2.day.ago.midnight, vv: { m: 50 })
          create(:site_day_stat, t: @site.token, d: 3.day.ago.midnight, vv: { m: 50 })
          create(:site_day_stat, t: @site.token, d: 4.day.ago.midnight, vv: { m: 50 })
          create(:site_day_stat, t: @site.token, d: 5.day.ago.midnight, vv: { m: 50 })
          create(:site_day_stat, t: @site.token, d: 6.day.ago.midnight, vv: { m: 50 })
        end

        its(:recommended_plan_name) { should be_nil }
      end

      context "with regular usage and video_views between plus and premium" do
        before(:each) do
          @site.unmemoize_all
          create(:site_day_stat, t: @site.token, d: 1.day.ago.midnight, vv: { m: 10_000 })
          create(:site_day_stat, t: @site.token, d: 2.day.ago.midnight, vv: { m: 10_000 })
          create(:site_day_stat, t: @site.token, d: 3.day.ago.midnight, vv: { m: 10_000 })
          create(:site_day_stat, t: @site.token, d: 4.day.ago.midnight, vv: { m: 10_000 })
          create(:site_day_stat, t: @site.token, d: 5.day.ago.midnight, vv: { m: 10_000 })
          create(:site_day_stat, t: @site.token, d: 6.day.ago.midnight, vv: { m: 10_000 })
        end

        its(:recommended_plan_name) { should eql "premium" }
      end

      context "with non regular usage and lower than video_views but greather than average video_views" do
        before(:each) do
          @site.unmemoize_all
          create(:site_day_stat, t: @site.token, d: 1.day.ago.midnight, vv: { m: 12_000 })
          create(:site_day_stat, t: @site.token, d: 2.day.ago.midnight, vv: { m: 12_000 })
          create(:site_day_stat, t: @site.token, d: 3.day.ago.midnight, vv: { m: 12_000 })
          create(:site_day_stat, t: @site.token, d: 4.day.ago.midnight, vv: { m: 12_000 })
          create(:site_day_stat, t: @site.token, d: 5.day.ago.midnight, vv: { m: 12_000 })
          create(:site_day_stat, t: @site.token, d: 6.day.ago.midnight, vv: { m: 1_000 })
        end

        its(:recommended_plan_name) { should eql "premium" }
      end

      context "with too much video_views" do
        before(:each) do
          @site.unmemoize_all
          create(:site_day_stat, t: @site.token, d: 1.day.ago.midnight, vv: { m: 500_000 })
          create(:site_day_stat, t: @site.token, d: 2.day.ago.midnight, vv: { m: 500_000 })
          create(:site_day_stat, t: @site.token, d: 3.day.ago.midnight, vv: { m: 500_000 })
          create(:site_day_stat, t: @site.token, d: 4.day.ago.midnight, vv: { m: 500_000 })
          create(:site_day_stat, t: @site.token, d: 5.day.ago.midnight, vv: { m: 500_000 })
        end

        its(:recommended_plan_name) { should eql "custom" }
      end

      context "with recommended plan lower than current plan" do
        before(:each) do
          @site.unmemoize_all
          @site.plan = @premium_plan
          create(:site_day_stat, t: @site.token, d: 1.day.ago.midnight, vv: { m: 500 })
          create(:site_day_stat, t: @site.token, d: 2.day.ago.midnight, vv: { m: 500 })
          create(:site_day_stat, t: @site.token, d: 3.day.ago.midnight, vv: { m: 500 })
          create(:site_day_stat, t: @site.token, d: 4.day.ago.midnight, vv: { m: 500 })
          create(:site_day_stat, t: @site.token, d: 5.day.ago.midnight, vv: { m: 500 })
        end

        its(:recommended_plan_name) { should be_nil }
      end
    end

    describe "#archivable?" do
      subject { @site.reload }

      context "first invoice" do
        before(:each) do
          Invoice.delete_all
          @site = create(:new_site, first_paid_plan_started_at: nil)
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          before(:each) do
            @open_invoice = create(:invoice, site: @site, state: 'open')
          end

          it { should be_archivable }
        end

        context "with a failed invoice" do
          before(:each) do
            @failed_invoice = create(:invoice, site: @site, state: 'failed')
          end

          it { should be_archivable }
        end

        context "with a waiting invoice" do
          before(:each) do
            @waiting_invoice = create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end

      context "not first invoice" do
        before(:each) do
          Invoice.delete_all
          @site = create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
          before(:each) do
            @open_invoice = create(:invoice, site: @site, state: 'open')
          end

          it { should_not be_archivable }
        end

        context "with a failed invoice" do
          before(:each) do
            @failed_invoice = create(:invoice, site: @site, state: 'failed')
          end

          it { should_not be_archivable }
        end

        context "with a waiting invoice" do
          before(:each) do
            @waiting_invoice = create(:invoice, site: @site, state: 'waiting')
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
#  id                                        :integer         not null, primary key
#  user_id                                   :integer
#  hostname                                  :string(255)
#  dev_hostnames                             :string(255)
#  token                                     :string(255)
#  license                                   :string(255)
#  loader                                    :string(255)
#  state                                     :string(255)
#  archived_at                               :datetime
#  created_at                                :datetime
#  updated_at                                :datetime
#  player_mode                               :string(255)     default("stable")
#  google_rank                               :integer
#  alexa_rank                                :integer
#  path                                      :string(255)
#  wildcard                                  :boolean
#  extra_hostnames                           :string(255)
#  plan_id                                   :integer
#  pending_plan_id                           :integer
#  next_cycle_plan_id                        :integer
#  cdn_up_to_date                            :boolean         default(FALSE)
#  first_paid_plan_started_at                :datetime
#  plan_started_at                           :datetime
#  plan_cycle_started_at                     :datetime
#  plan_cycle_ended_at                       :datetime
#  pending_plan_started_at                   :datetime
#  pending_plan_cycle_started_at             :datetime
#  pending_plan_cycle_ended_at               :datetime
#  overusage_notification_sent_at            :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#  refunded_at                               :datetime
#  last_30_days_main_video_views             :integer         default(0)
#  last_30_days_extra_video_views            :integer         default(0)
#  last_30_days_dev_video_views              :integer         default(0)
#  trial_started_at                          :datetime
#  badged                                    :boolean
#  last_30_days_invalid_video_views          :integer         default(0)
#  last_30_days_embed_video_views            :integer         default(0)
#  last_30_days_billable_video_views_array   :text
#
# Indexes
#
#  index_sites_on_created_at                        (created_at)
#  index_sites_on_hostname                          (hostname)
#  index_sites_on_last_30_days_dev_video_views      (last_30_days_dev_video_views)
#  index_sites_on_last_30_days_embed_video_views    (last_30_days_embed_video_views)
#  index_sites_on_last_30_days_extra_video_views    (last_30_days_extra_video_views)
#  index_sites_on_last_30_days_invalid_video_views  (last_30_days_invalid_video_views)
#  index_sites_on_last_30_days_main_video_views     (last_30_days_main_video_views)
#  index_sites_on_plan_id                           (plan_id)
#  index_sites_on_user_id                           (user_id)
#

