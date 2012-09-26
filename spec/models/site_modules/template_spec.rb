require 'spec_helper'

describe SiteModules::Template do

  pending "Callbacks" do

    context "on create" do
      let(:site) { build(:new_site) }

      it "delays .update_loader_and_license once" do
        -> { site.save! }.should delay('%update_loader_and_license%')
      end

      it "updates loader and license content" do
        site.loader.read.should be_nil
        site.license.read.should be_nil

        site.apply_pending_attributes
        $worker.work_off

        site.reload.loader.read.should be_present
        site.license.read.should be_present
      end

      it "sets cdn_up_to_date to true" do
        site.cdn_up_to_date.should be_false
        site.apply_pending_attributes
        $worker.work_off

        site.reload.cdn_up_to_date.should be_true
      end

      it "doesn't purge loader nor license file" do
        CDN.should_not_receive(:purge)

        site.apply_pending_attributes
        $worker.work_off
      end

      # it "delays Player::Settings.update!" do
      #   -> { site.save! }.should delay('%Player::Settings%update!%')
      # end
    end

    describe "on save" do
      before { CDN.stub(:purge) }

      describe "plan_id has changed" do
        let(:site) { create(:site, plan_id: @free_plan.id) }
        before do
          # site
          Delayed::Job.delete_all
          site.plan_id = @paid_plan.id
        end

        it "delays .update_loader_and_license once" do
          -> { site.apply_pending_attributes }.should delay('%update_loader_and_license%')
        end

        # it "delays Player::Settings.update!" do
        #   -> { site.apply_pending_attributes }.should delay('%Player::Settings%update!%')
        # end

        it "purges loader & license & settings on CDN" do
          CDN.should_receive(:purge).exactly(2).times # 2x each

          site.apply_pending_attributes
          $worker.work_off
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
          let(:site) { create(:site, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true, badged: false) }
          before do
            site
            $worker.work_off
            site.reload
          end

          it "delays .update_loader_and_license once" do
            site.send("#{attr}=", value)
            site.user.current_password = '123456'
            -> { site.save }.should delay('%update_loader_and_license%')
          end

          # it "delays Player::Settings.update!" do
          #   site.send("#{attr}=", value)
          #   site.user.current_password = '123456'
          #   -> { site.save }.should delay('%Player::Settings%update!%')
          # end

          it "updates license content with #{attr}" do
            old_license_content = site.license.read
            site.send("#{attr}=", value)
            site.user.current_password = '123456'
            site.apply_pending_attributes
            $worker.work_off

            site.reload
            site.license.read.should_not eq old_license_content
          end

          it "purges license on CDN" do
            CDN.should_receive(:purge).with("/l/#{site.token}.js")

            site.send("#{attr}=", value)
            site.user.current_password = '123456'
            site.save!
            $worker.work_off
          end
        end
      end

      describe "player_mode has changed" do
        let(:site) { create(:site, player_mode: 'dev') }
        before do
          site
          $worker.work_off
          site.reload
        end

        it "should delay update_loader_and_license once" do
          -> { site.update_attribute(:player_mode, 'beta') }.should delay('%update_loader_and_license%')
        end

        # it "delays Player::Settings.update!" do
        #   -> { site.update_attribute(:player_mode, 'beta') }.should delay('%Player::Settings%update!%')
        # end

        it "should update loader content" do
          old_loader_content = site.loader.read
          site.update_attribute(:player_mode, 'beta')
          $worker.work_off
          site.reload.loader.read.should_not eq old_loader_content
        end

        it "should purge loader on CDN" do
          CDN.should_receive(:purge).with("/js/#{site.token}.js")
          site.update_attribute(:player_mode, 'beta')
          $worker.work_off
        end

        it "notifies that cdn is up to date via Pusher" do
          site.update_attribute(:player_mode, 'beta')
          PusherWrapper.should_receive(:trigger).once.with("private-#{site.token}", 'cdn_status', up_to_date: true)
          Timecop.travel(3.minutes.from_now) { $worker.work_off }
        end
      end

    end

  end # Callbacks

  pending "Instance Methods" do

    describe "#settings_changed?" do
      let(:site) { create(:site) }

      it "should return false if no attribute has changed" do
        site.should_not be_settings_changed
      end

      { hostname: "jilion.com", extra_hostnames: "test.staging.com", dev_hostnames: "test.local", path: "yu", wildcard: true, badged: false }.each do |attribute, value|
        it "should return true if #{attribute} has changed" do
          site.send("#{attribute}=", value)
          site.should be_settings_changed
        end
      end
    end

    describe "#license_hash" do
      describe "common settings" do
        let(:site) { create(:site, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true, badged: true) }

        it "includes everything" do
          site.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: true, s: true, r: true }
        end

        context "without extra_hostnames" do
          before { site.extra_hostnames = '' }

          it "removes extra_hostnames from h: []" do
            site.license_hash.should == { h: ['jilion.com'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: true, s: true, r: true }
          end
        end

        context "without path" do
          before { site.path = '' }

          it "doesn't include path key/value" do
            site.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, b: true, s: true, r: true }
          end
        end

        context "without wildcard" do
          before { site.wildcard = false }

          it "doesn't include wildcard key/value" do
            site.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], p: "foo", b: true, s: true, r: true }
          end
        end

        context "without badged" do
          before { site.badged = false }

          it "includes b: false" do
            site.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: false, s: true, r: true }
          end
        end

        context "without ssl (free plan)" do
          before do
            site.plan_id = @free_plan.id
            site.apply_pending_attributes
          end

          it "includes ssl: false" do
            site.should be_in_free_plan
            site.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, b: true, p: "foo" }
          end
        end

        context "without realtime data (free plan)" do
          before do
            site.plan_id = @free_plan.id
            site.apply_pending_attributes
          end

          it "doesn't includes r: true" do
            site.should be_in_free_plan
            site.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: true }
          end
        end

        context "with only a pending plan" do
          before do
            site.send(:write_attribute, :plan_id, nil)
            site.pending_plan_id = @paid_plan.id
          end

          it "doesn't includes r: true" do
            site.plan_id.should be_nil
            site.plan.should be_nil
            site.pending_plan.should be_present
            site.license_hash.should == { h: ['jilion.com', 'jilion.net', 'jilion.org'], d: ['127.0.0.1', 'localhost'], w: true, p: "foo", b: true, s: true }
          end
        end
      end

    end

    describe "#license_js_hash" do
      subject { create(:site, plan_id: @trial_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true) }

      its(:license_js_hash) { should eq "{h:[\"jilion.com\",\"jilion.net\",\"jilion.org\"],d:[\"127.0.0.1\",\"localhost\"],w:true,p:\"foo\",b:true,s:true,r:true}" }
    end

    describe "#set_template" do
      context "unknown template" do
        let(:site) {
          site = build(:site)
          site.license.read.should be_nil
          site.set_template("foobar")
          site
        }

        it "sets license file with license_hash" do
          site.license.read.should be_nil
        end
      end

      context "license" do
        let(:site) {
          site = create(:site, plan_id: @trial_plan.id, hostname: "jilion.com", extra_hostnames: "jilion.net, jilion.org", dev_hostnames: '127.0.0.1,localhost', path: 'foo', wildcard: true)
          site.set_template("license")
          site
        }

        it "sets license file with license_hash" do
          site.license.read.should eq "jilion.sublime.video.sites({h:[\"jilion.com\",\"jilion.net\",\"jilion.org\"],d:[\"127.0.0.1\",\"localhost\"],w:true,p:\"foo\",b:true,s:true,r:true});"
        end
      end

      context "license with prefix" do
        context "file exists" do
          let(:site) {
            site = build(:site)
            File.should_receive(:new).with(Rails.root.join("app/templates/sites/foo_license.js.erb")) { @file = mock('file', read: "new license") }
            site.set_template("license", prefix: 'foo')
            site
          }

          it "uses prefixed license template" do
            site.license.read.should eq "new license"
          end
        end

        context "file doesn't exist" do
          let(:site) { create(:site, hostname: "jilion.com").tap { |s| s.set_template("license", prefix: 'bar') } }

          it "use standard license" do
            site.license.read.should eq "jilion.sublime.video.sites({h:[\"jilion.com\"],d:[\"127.0.0.1\",\"localhost\"],b:true,s:true,r:true});"
          end
        end
      end

      context "loader" do
        let(:site) { create(:site).tap { |s| s.set_template("loader") } }

        it "sets loader file with token" do
          site.loader.read.should include(site.token)
        end

        it "sets loader file with stable player_mode" do
          site.loader.read.should include("/p/sublime.js.jgz?t=#{site.token}")
        end
      end

      context "loader with prefix" do
        context "file exists" do
          let(:site) {
            site = build(:site)
            File.should_receive(:new).with(Rails.root.join("app/templates/sites/foo_loader.js.erb")) { @file = mock('file', read: "new loader") }
            site.set_template("loader", prefix: 'foo')
            site
          }

          it "uses prefixed loader template" do
            site.loader.read.should eq "new loader"
          end
        end

        context "file doesn't exist" do
          let(:site) { build(:site).tap { |s| s.set_template("loader", prefix: 'bar') } }

          it "use standard loader" do
            site.loader.read.should include("/p/sublime.js.jgz?t=#{site.token}")
          end
        end
      end
    end

  end

end
