require 'spec_helper'

describe Site::Templates do

  describe "Callbacks" do

    describe "before_save" do
      subject { Factory(:site, plan_id: @paid_plan.id) }

      specify do
        subject.should_receive(:prepare_cdn_update)
        subject.save!
      end
    end

    describe "after_save" do
      before(:each) { VoxcastCDN.stub(:purge) }

      context "on create" do
        subject { Factory(:site_pending) }

        it "should delay update_loader_and_license once" do
          subject
          count_before = Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count
          lambda { subject.apply_pending_plan_changes }.should change(Delayed::Job, :count).by(1)
          djs = Delayed::Job.where(:handler.matches => "%update_loader_and_license%")
          djs.count.should == count_before + 1
          YAML.load(djs.first.handler)['args'][0].should be_true
          YAML.load(djs.first.handler)['args'][1].should be_true
        end

        it "should update loader and license content" do
          subject.loader.read.should be_nil
          subject.license.read.should be_nil
          subject.apply_pending_plan_changes
          @worker.work_off
          subject.reload.loader.read.should be_present
          subject.license.read.should be_present
        end

        it "should set cdn_up_to_date to true" do
          subject.apply_pending_plan_changes
          subject.cdn_up_to_date.should be_false
          @worker.work_off
          subject.reload.cdn_up_to_date.should be_true
        end

        it "should not purge loader or license file" do
          VoxcastCDN.should_not_receive(:purge)
          subject.apply_pending_plan_changes
          @worker.work_off
        end
      end

      context "on update of settings or state (to dev or active)" do
        describe "attributes that appears in the license" do

          before(:each) do
            PageRankr.stub(:ranks)
          end

          { hostname: "test.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true }.each do |attribute, value|
            describe "#{attribute} has changed" do
              subject do
                site = Factory(:site, plan_id: @dev_plan.id, hostname: "jilion.com", extra_hostnames: "staging.jilion.com", dev_hostnames: "jilion.local", path: "yo", wildcard: false)
                @worker.work_off
                site.reload
              end

              it "should delay update_loader_and_license once" do
                subject
                lambda { subject.update_attribute(attribute, value) }.should change(Delayed::Job, :count).by(1)
                Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count.should == 1
              end

              it "should update license content with #{attribute} only when site have a dev plan" do
                old_license_content = subject.license.read
                subject.send("#{attribute}=", value)
                subject.save
                @worker.work_off

                subject.reload
                if [:dev_hostnames, :wildcard].include?(attribute)
                  subject.license.read.should_not == old_license_content
                  subject.license.read.should include(value.to_s)
                else
                  subject.license.read.should == old_license_content
                  subject.license.read.should_not include(value.to_s)
                end
              end

              it "should update license content with #{attribute} value when site have a paid plan" do
                old_license_content = subject.license.read
                subject.send("#{attribute}=", value)
                subject.user.current_password = '123456'
                subject.plan_id = @paid_plan.id
                subject.apply_pending_plan_changes
                @worker.work_off

                subject.reload
                subject.license.read.should_not == old_license_content
                subject.license.read.should include(value.to_s)
              end

              it "should purge license on CDN" do
                VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")
                subject.update_attribute(attribute, value)
                @worker.work_off
              end
            end
          end
        end

        describe "attributes that appears in the loader" do
          describe "player_mode has changed" do
            subject do
              site = Factory(:site, player_mode: 'dev')
              @worker.work_off
              site.reload
            end

            it "should delay update_loader_and_license once" do
              subject
              lambda { subject.update_attribute(:player_mode, 'beta') }.should change(Delayed::Job, :count).by(1)
              Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count.should == 1
            end

            it "should update loader content" do
              old_loader_content = subject.loader.read
              subject.update_attribute(:player_mode, 'beta')
              @worker.work_off
              subject.reload.loader.read.should_not == old_loader_content
            end

            it "should purge loader on CDN" do
              VoxcastCDN.should_receive(:purge).with("/js/#{subject.token}.js")
              subject.update_attribute(:player_mode, 'beta')
              @worker.work_off
            end
          end
        end
      end

    end # after_save

  end # Callbacks

  describe "Instance Methods" do

    describe "#prepare_cdn_update" do

      context "new record with dev plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan_id: @dev_plan.id)
          @site.send :prepare_cdn_update
        end
        subject { @site }

        its(:plan_id)              { should be_nil }
        its(:pending_plan_id)      { should == @dev_plan.id }
        its(:cdn_up_to_date)       { should be_true }
        its(:loader_needs_update)  { should be_false }
        its(:license_needs_update) { should be_false }
      end

      context "new record with paid plan" do
        before(:all) do
          @site = Factory.build(:new_site, plan_id: @paid_plan.id)
          @site.send :prepare_cdn_update
        end
        subject { @site }

        its(:plan_id)              { should be_nil }
        its(:pending_plan_id)      { should == @paid_plan.id }
        its(:cdn_up_to_date)       { should be_true }
        its(:loader_needs_update)  { should be_false }
        its(:license_needs_update) { should be_false }
      end

      context "new record with dev plan (apply_pending_plan_changes called)" do
        before(:all) do
          @site = Factory.build(:new_site, plan_id: @dev_plan.id)
          @site.save
        end
        subject { @site }

        its(:plan_id)              { should == @dev_plan.id  }
        its(:pending_plan_id)      { should be_nil }
        its(:cdn_up_to_date)       { should be_false }
        its(:loader_needs_update)  { should be_true }
        its(:license_needs_update) { should be_true }

        describe "when change player_mode" do
          before(:all) do
            @site.reload.player_mode = "beta"
            @site.send :prepare_cdn_update
          end
          subject { @site }

          its(:cdn_up_to_date)       { should be_false }
          its(:loader_needs_update)  { should be_true }
          its(:license_needs_update) { should be_false }
        end

        { hostname: "test.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true }.each do |attribute, value|
          describe "when #{attribute} has changed" do
            before(:all) do
              @site.reload.send("#{attribute}=", value)
              @site.send :prepare_cdn_update
            end
            subject { @site }

            its(:cdn_up_to_date)       { should be_false }
            its(:loader_needs_update)  { should be_false }
            its(:license_needs_update) { should be_true }
          end
        end

        describe "when upgrade" do
          before(:all) do
            @site = Factory(:site, plan_id: @dev_plan.id)
            @site.plan_id = @paid_plan.id
            @site.send :prepare_cdn_update
          end
          subject { @site }

          its(:plan_id)              { should == @dev_plan.id }
          its(:pending_plan_id)      { should == @paid_plan.id }
          its(:cdn_up_to_date)       { should be_true }
          its(:loader_needs_update)  { should be_false }
          its(:license_needs_update) { should be_false }
        end

        describe "when upgrade (apply_pending_plan_changes called)" do
          before(:all) do
            @site = Factory(:site, plan_id: @dev_plan.id)
            @site.plan_id = @paid_plan.id
            VCR.use_cassette('ogone/visa_payment_generic') do
              @site.pend_plan_changes
              @site.apply_pending_plan_changes
            end
          end
          subject { @site }

          its(:plan_id)              { should == @paid_plan.id  }
          its(:pending_plan_id)      { should be_nil }
          its(:cdn_up_to_date)       { should be_false }
          its(:loader_needs_update)  { should be_false }
          its(:license_needs_update) { should be_true }
        end
      end

      context "new record with paid plan (apply_pending_plan_changes called)" do
        before(:all) do
          @site = Factory.build(:new_site, plan_id: @paid_plan.id)
          VCR.use_cassette('ogone/visa_payment_generic') do
            @site.pend_plan_changes
            @site.apply_pending_plan_changes
          end
        end
        subject { @site }

        its(:plan_id)              { should == @paid_plan.id  }
        its(:pending_plan_id)      { should be_nil }
        its(:cdn_up_to_date)       { should be_false }
        its(:loader_needs_update)  { should be_true }
        its(:license_needs_update) { should be_true }

        describe "when change player_mode" do
          before(:all) do
            @site.reload.player_mode = "beta"
            @site.send :prepare_cdn_update
          end
          subject { @site }

          its(:cdn_up_to_date)       { should be_false }
          its(:loader_needs_update)  { should be_true }
          its(:license_needs_update) { should be_false }
        end

        { hostname: "test.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true }.each do |attribute, value|
          describe "when #{attribute} has changed" do
            before(:all) do
              @site.reload.send("#{attribute}=", value)
              @site.send :prepare_cdn_update
            end
            subject { @site }

            its(:cdn_up_to_date)       { should be_false }
            its(:loader_needs_update)  { should be_false }
            its(:license_needs_update) { should be_true }
          end
        end

        describe "when downgrade" do
          before(:all) do
            @site = Factory(:site, plan_id: @paid_plan.id)
            @site.plan_id = @dev_plan.id
            @site.send :prepare_cdn_update
          end
          subject { @site }

          its(:plan_id)              { should == @paid_plan.id  }
          its(:pending_plan_id)      { should be_nil }
          its(:next_cycle_plan_id)   { should == @dev_plan.id }
          its(:cdn_up_to_date)       { should be_true }
          its(:loader_needs_update)  { should be_false }
          its(:license_needs_update) { should be_false }
        end

        describe "when upgrade" do
          before(:all) do
            @site = Factory(:site, plan_id: @paid_plan.id)
            @site.plan_id = @custom_plan.token
            @site.send :prepare_cdn_update
          end
          subject { @site }

          its(:plan_id)              { should == @paid_plan.id }
          its(:pending_plan_id)      { should == @custom_plan.id }
          its(:cdn_up_to_date)       { should be_true }
          its(:loader_needs_update)  { should be_false }
          its(:license_needs_update) { should be_false }
        end

        describe "when unsuspend" do
          before(:all) do
            @site = Factory(:site, plan_id: @paid_plan.id)
            @site.suspend
            @site.reload
            @site.unsuspend
          end
          subject { @site }

          its(:plan_id)              { should == @paid_plan.id }
          its(:pending_plan_id)      { should be_nil }
          its(:cdn_up_to_date)       { should be_false }
          its(:loader_needs_update)  { should be_true }
          its(:license_needs_update) { should be_true }
        end

        describe "when upgrade (apply_pending_plan_changes called)" do
          before(:all) do
            @site = Factory(:site, plan_id: @paid_plan.id)
            @site.plan_id = @custom_plan.token
            VCR.use_cassette('ogone/visa_payment_generic') do
              @site.pend_plan_changes
              @site.apply_pending_plan_changes
            end
          end
          subject { @site }

          its(:plan_id)              { should == @custom_plan.id }
          its(:pending_plan_id)      { should be_nil }
          its(:cdn_up_to_date)       { should be_true }
          its(:loader_needs_update)  { should be_false }
          its(:license_needs_update) { should be_false }
        end
      end
    end # #prepare_cdn_update

    describe "#settings_changed?" do
      subject { Factory(:site) }

      it "should return false if no attribute has changed" do
        subject.should_not be_settings_changed
      end

      { hostname: "jilion.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true }.each do |attribute, value|
        it "should return true if #{attribute} has changed" do
          subject.send("#{attribute}=", value)
          subject.should be_settings_changed
        end
      end
    end

    describe "#license_hash" do
      before(:all) do
        @site_with_all = Factory(:site, plan_id: @dev_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true)
        @site_without_wildcard = Factory(:site, plan_id: @dev_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: false)
        @site_without_path = Factory(:site, plan_id: @dev_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', wildcard: true)
        @site_without_extra_hostnames = Factory(:site, plan_id: @dev_plan.id, hostname: "jilion.com", dev_hostnames: '127.0.0.1,localhost', wildcard: true)
      end

      context "site with dev plan" do
        context "site with all settings" do
          subject { @site_with_all }
          it "should include only dev hostnames without path" do
            subject.reload.license_hash.should == { d: ['127.0.0.1', 'localhost'], w: true }
          end
        end

        context "site without wildcard" do
          subject { @site_without_wildcard }
          it "should include only dev hostnames without path and wildcard" do
            subject.license_hash.should == { d: ['127.0.0.1', 'localhost'] }
          end
        end


        context "site without path" do
          subject { @site_without_path.reload }
          it "should include only dev hostnames without path" do
            subject.reload.license_hash.should == { d: ['127.0.0.1', 'localhost'], w: true }
          end
        end
      end

      %w[sponsored beta paid].each do |plan_name|
        context "site with #{plan_name} plan" do
          context "site with all settings" do
            subject { @site_with_all.reload }
            it "should include hostname, extra_hostnames, path, wildcard & dev_hostnames" do
              subject.plan = instance_variable_get(:"@#{plan_name}_plan")
              subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], p: "foo", d: ['127.0.0.1', 'localhost'], w: true }
            end
          end

          context "site without wildcard" do
            subject { @site_without_wildcard.reload }
            it "should include hostname, extra_hostnames, path, no wildcard & dev_hostnames" do
              subject.plan = instance_variable_get(:"@#{plan_name}_plan")
              subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], p: "foo", d: ['127.0.0.1', 'localhost'] }
            end
          end

          context "site without path" do
            subject { @site_without_path.reload }
            it "should include hostname, extra_hostnames, no path, wildcard & dev_hostnames" do
              subject.plan = instance_variable_get(:"@#{plan_name}_plan")
              subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true }
            end
          end

          context "site without extra_hostnames" do
            subject { @site_without_extra_hostnames.reload }
            it "should include hostname, no extra_hostnames, path, wildcard & dev_hostnames" do
              subject.plan = instance_variable_get(:"@#{plan_name}_plan")
              subject.license_hash.should == { h: ['jilion.com'], d: ['127.0.0.1', 'localhost'], w: true }
            end
          end

        end
      end
    end

    describe "#set_template" do
      context "license" do
        before(:all) do
          @site = Factory(:site, plan_id: @paid_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true)
          @site.tap { |s| s.set_template("license") }
        end
        subject { @site }

        it "should set license file with license_hash" do
          subject.license.read.should == "jilion.sublime.video.sites({h:[\"jilion.com\",\"jilion.net\",\"jilion.org\"],p:\"foo\",d:[\"127.0.0.1\",\"localhost\"],w:true});"
        end
      end

      context "loader" do
        before(:all) do
          @site = Factory(:site).tap { |s| s.set_template("loader") }
        end
        subject { @site }

        it "should set loader file with token" do
          subject.loader.read.should include(subject.token)
        end

        it "should set loader file with stable player_mode" do
          subject.loader.read.should include("/p/sublime.js?t=#{subject.token}")
        end
      end
    end

  end

end
