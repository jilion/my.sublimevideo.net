require 'spec_helper'

describe SiteModules::Templates do

  describe "Callbacks" do

    context "on create" do
      subject { FactoryGirl.build(:new_site) }

      it "delays .update_loader_and_license once" do
        expect { subject.save! }.to change(Delayed::Job.where(:handler.matches => "%update_loader_and_license%"), :count).by(1)
      end

      it "updates loader and license content" do
        subject.loader.read.should be_nil
        subject.license.read.should be_nil

        subject.apply_pending_plan_changes
        @worker.work_off

        subject.reload.loader.read.should be_present
        subject.license.read.should be_present
      end

      it "sets cdn_up_to_date to true" do
        subject.cdn_up_to_date.should be_false
        subject.apply_pending_plan_changes
        @worker.work_off

        subject.reload.cdn_up_to_date.should be_true
      end

      it "doesn't purge loader nor license file" do
        VoxcastCDN.should_not_receive(:purge)

        subject.apply_pending_plan_changes
        @worker.work_off
      end
    end

    describe "on save" do
      before do
        # PageRankr.stub(:ranks)
        VoxcastCDN.stub(:purge)
      end

      describe "plan_id has changed" do
        subject { FactoryGirl.create(:site, plan_id: @free_plan.id) }
        before(:each) { subject.plan_id = @paid_plan.id }

        it "delays .update_loader_and_license once" do
          expect { subject.save! }.to change(Delayed::Job.where(:handler.matches => "%update_loader_and_license%"), :count).by(1)
        end

        it "purges loader & license on CDN" do
          VoxcastCDN.should_receive(:purge).twice

          subject.save!
          @worker.work_off
        end
      end

      [ [:hostname, :h, "test.com"],
        [:extra_hostnames, :h, "test.staging.com"],
        [:dev_hostnames, :d, "test.local"],
        [:wildcard, :w, false],
        [:path, :p, "yu"]
      ].each do |attr, key, value|
        describe "and #{attr} setting has changed" do
          before(:all) do
            @site = FactoryGirl.create(:site, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true)
            @worker.work_off
          end
          subject { @site.reload }

          it "delays .update_loader_and_license once" do
            subject.send("#{attr}=", value)
            subject.user.current_password = '123456'
            expect { subject.save }.to change(Delayed::Job.where(:handler.matches => "%update_loader_and_license%"), :count).by(1)
          end

          it "updates license content with #{attr}" do
            old_license_content = subject.license.read
            subject.send("#{attr}=", value)
            subject.user.current_password = '123456'
            subject.apply_pending_plan_changes
            @worker.work_off

            subject.reload
            subject.license.read.should_not == old_license_content
            if value === false
              subject.license.read.should_not include("#{key}:")
              subject.license.read.should_not include(value.to_s)
            else
              subject.license.read.should include("#{key}:")
              subject.license.read.should include(value.to_s)
            end
          end

          it "purges license on CDN" do
            VoxcastCDN.should_receive(:purge).with("/l/#{subject.token}.js")

            subject.send("#{attr}=", value)
            subject.user.current_password = '123456'
            subject.save!
            @worker.work_off
          end
        end
      end

      describe "player_mode has changed" do
        subject do
          site = FactoryGirl.create(:site, player_mode: 'dev')
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

  end # Callbacks

  describe "Instance Methods" do

    describe "#settings_changed?" do
      subject { FactoryGirl.create(:site) }

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
        @site = FactoryGirl.create(:site, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true)
      end

      describe "common settings" do
        subject { @site.reload }

        it "includes everything" do
          subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo" }
        end

        context "without extra_hostnames" do
          before { subject.extra_hostnames = '' }

          it "should include hostname, no extra_hostnames, path, wildcard & dev_hostnames" do
            subject.license_hash.should == { h: ['jilion.com'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo" }
          end
        end

        context "without wildcard" do
          before { subject.wildcard = false }

          it "should include hostname, extra_hostnames, path, no wildcard & dev_hostnames" do
            subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], p: "foo" }
          end
        end

        context "without path" do
          before { subject.path = '' }

          it "should include hostname, extra_hostnames, no path, wildcard & dev_hostnames" do
            subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true }
          end
        end
      end

      describe "brand" do
      end

      describe "ssl" do
      end

    end

    describe "#license_js_hash" do
      subject{ FactoryGirl.create(:site, plan_id: @paid_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true) }

      its(:license_js_hash) { should == "{h:[\"jilion.com\",\"jilion.net\",\"jilion.org\"],d:[\"127.0.0.1\",\"localhost\"],w:true,p:\"foo\"}" }
    end

    describe "#set_template" do
      context "license" do
        before(:all) do
          @site = FactoryGirl.create(:site, plan_id: @paid_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true)
          @site.tap { |s| s.set_template("license") }
        end
        subject { @site }

        it "should set license file with license_hash" do
          subject.license.read.should == "jilion.sublime.video.sites({h:[\"jilion.com\",\"jilion.net\",\"jilion.org\"],d:[\"127.0.0.1\",\"localhost\"],w:true,p:\"foo\"});"
        end
      end

      context "loader" do
        before(:all) do
          @site = FactoryGirl.create(:site).tap { |s| s.set_template("loader") }
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
