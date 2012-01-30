require 'spec_helper'

describe SiteModules::Templates do

  describe "Callbacks" do

    context "on create" do
      subject { Factory.build(:new_site) }

      it "delays .update_loader_and_license once" do
        expect { subject.save! }.to change(Delayed::Job.where(:handler.matches => "%update_loader_and_license%"), :count).by(1)
      end

      it "updates loader and license content" do
        subject.loader.read.should be_nil
        subject.license.read.should be_nil

        subject.apply_pending_attributes
        @worker.work_off

        subject.reload.loader.read.should be_present
        subject.license.read.should be_present
      end

      it "sets cdn_up_to_date to true" do
        subject.cdn_up_to_date.should be_false
        subject.apply_pending_attributes
        @worker.work_off

        subject.reload.cdn_up_to_date.should be_true
      end

      it "doesn't purge loader nor license file" do
        VoxcastCDN.should_not_receive(:purge)

        subject.apply_pending_attributes
        @worker.work_off
      end
    end

    describe "on save" do
      before(:each) do
        VoxcastCDN.stub(:purge)
      end

      describe "plan_id has changed" do
        subject { Factory.create(:site, plan_id: @free_plan.id) }
        before(:each) { subject.plan_id = @paid_plan.id }

        it "delays .update_loader_and_license once" do
          expect { subject.save! }.to change(Delayed::Job.where { handler =~ "%update_loader_and_license%" }, :count).by(1)
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
        [:path, :p, "yu"],
        [:badged, :b, true]
      ].each do |attr, key, value|
        describe "and #{attr} setting has changed" do
          before(:each) do
            @site = Factory.create(:site, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true, badged: false)
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
            subject.apply_pending_attributes
            @worker.work_off

            subject.reload
            subject.license.read.should_not == old_license_content
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
          site = Factory.create(:site, player_mode: 'dev')
          @worker.work_off
          site.reload
        end

        it "should delay update_loader_and_license once" do
          subject
          lambda { subject.update_attribute(:player_mode, 'beta') }.should change(Delayed::Job, :count).by(1)
          Delayed::Job.where(:handler.matches => "%update_loader_and_license%").should have(1).item
        end

        it "should update loader content" do
          old_loader_content = subject.loader.read
          subject.update_attribute(:player_mode, 'beta')
          @worker.work_off
          subject.reload.loader.read.should_not eq old_loader_content
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
      subject { Factory.create(:site) }

      it "should return false if no attribute has changed" do
        subject.should_not be_settings_changed
      end

      { hostname: "jilion.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true, badged: true }.each do |attribute, value|
        it "should return true if #{attribute} has changed" do
          subject.send("#{attribute}=", value)
          subject.should be_settings_changed
        end
      end
    end

    describe "#license_hash" do
      before(:all) do
        @site = Factory.create(:site, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true, badged: true)
      end

      describe "common settings" do
        subject { @site.reload }

        it "includes everything" do
          subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: true, s: true, r: true }
        end

        context "without extra_hostnames" do
          before { subject.extra_hostnames = '' }

          it "removes extra_hostnames from h: []" do
            subject.license_hash.should == { h: ['jilion.com'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: true, s: true, r: true }
          end
        end

        context "without path" do
          before { subject.path = '' }

          it "doesn't include path key/value" do
            subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, b: true, s: true, r: true }
          end
        end

        context "without wildcard" do
          before { subject.wildcard = false }

          it "doesn't include wildcard key/value" do
            subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], p: "foo", b: true, s: true, r: true }
          end
        end

        context "without badged" do
          before { subject.badged = false }

          it "includes b: false" do
            subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: false, s: true, r: true }
          end
        end

        context "without ssl (free plan)" do
          before { subject.plan_id = @free_plan.id; subject.apply_pending_attributes }

          it "includes ssl: false" do
            subject.should be_in_free_plan
            subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, b: true, p: "foo" }
          end
        end

        context "without realtime data (free plan)" do
          before { subject.plan_id = @free_plan.id; subject.apply_pending_attributes }

          it "doesn't includes r: true" do
            subject.should be_in_free_plan
            subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: true }
          end
        end

        context "with only a pending plan" do
          before { subject.send(:write_attribute, :plan_id, nil); subject.pending_plan_id = @paid_plan.id }

          it "doesn't includes r: true" do
            subject.plan_id.should be_nil
            subject.plan.should be_nil
            subject.pending_plan.should be_present
            subject.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: true, s: true }
          end
        end
      end

    end

    describe "#license_js_hash" do
      subject{ Factory.create(:site, plan_id: @paid_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true) }

      its(:license_js_hash) { should == "{h:[\"jilion.com\",\"jilion.net\",\"jilion.org\"],d:[\"127.0.0.1\",\"localhost\"],w:true,p:\"foo\",b:false,s:true,r:true}" }
    end

    describe "#set_template" do
      context "license" do
        before(:all) do
          @site = Factory.create(:site, plan_id: @paid_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true)
          @site.tap { |s| s.set_template("license") }
        end
        subject { @site }

        it "should set license file with license_hash" do
          subject.license.read.should == "jilion.sublime.video.sites({h:[\"jilion.com\",\"jilion.net\",\"jilion.org\"],d:[\"127.0.0.1\",\"localhost\"],w:true,p:\"foo\",b:false,s:true,r:true});"
        end
      end

      context "loader" do
        before(:all) do
          @site = Factory.create(:site).tap { |s| s.set_template("loader") }
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
