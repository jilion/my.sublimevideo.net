require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'

# for fog_mock
require 'carrierwave'
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')

require File.expand_path('lib/s3')
require File.expand_path('app/models/player')
require File.expand_path('app/models/player/settings')

Site = Class.new unless defined?(Site)

describe Player::Settings, :fog_mock do
  before { CDN.stub(:purge) }

  let(:site) { mock("Site",
    id: 1,
    token: 'abcd1234',
    hostname: 'test.com',
    extra_hostnames: 'test.net', extra_hostnames?: true,
    dev_hostnames: 'test.dev', dev_hostnames?: true,
    wildcard: true, wildcard?: true,
    path: 'path', path?: true,
    badged: true,
    in_free_plan?: false,
    plan_stats_retention_days: 365,
    touch: true
  )}
  let(:settings) { Player::Settings.new(site, 'settings') }

  describe ".update_all_types!" do
    before { Site.stub(:find) { site } }

    context "site active" do
      before { site.stub(:state) { 'active' } }

      it "uploads all settings types" do
        Player::Settings.update_all_types!(site.id)
        Player::Settings.new(site, 'license').should be_present
        Player::Settings.new(site, 'settings').should be_present
      end

      it "touch update_all_types" do
        site.should_receive(:touch).with(:settings_updated_at)
        Player::Settings.update_all_types!(site.id)
      end

      context "when suspended" do
        before { site.stub(:state) { 'suspended' } }

        it "removes all settings types" do
          Player::Settings.update_all_types!(site.id)
          Player::Settings.new(site, 'license').should_not be_present
          Player::Settings.new(site, 'settings').should_not be_present
        end
      end
    end
  end

  describe "file" do
    context "with license type" do
      let(:file) { Player::Settings.new(site, 'license').file }

      it "have good content" do
        File.open(file) do |f|
          f.read.should eq "jilion.sublime.video.sites({\"h\":[\"test.com\",\"test.net\"],\"d\":[\"test.dev\"],\"w\":true,\"p\":\"path\",\"b\":true,\"s\":true,\"r\":true});\n"
        end
      end
    end

    context "with settings type" do
      let(:file) { Player::Settings.new(site, 'settings').file }

      it "have good content" do
        File.open(file) do |f|
          f.read.should eq "sublime_.module(\"license\", [], function() {\n  var license;\n  license =  {\"h\":[\"test.com\",\"test.net\"],\"d\":[\"test.dev\"],\"w\":true,\"p\":\"path\",\"b\":true,\"s\":true,\"r\":true}\n  return [license];\n});\n"
        end
      end
    end
  end

  describe "#hash" do
    describe "common settings" do

      it "includes everything" do
        settings.hash.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: true, s: true, r: true }
      end

      context "without extra_hostnames" do
        before { site.stub(extra_hostnames?: false) }

        it "removes extra_hostnames from h: []" do
          settings.hash.should == { h: ['test.com'], d: ['test.dev'], w: true, p: "path", b: true, s: true, r: true }
        end
      end

      context "without path" do
        before { site.stub(path?: false) }

        it "doesn't include path key/value" do
          settings.hash.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, b: true, s: true, r: true }
        end
      end

      context "without wildcard" do
        before { site.stub(wildcard?: false) }

        it "doesn't include wildcard key/value" do
          settings.hash.should == { h: ['test.com', 'test.net'], d: ['test.dev'], p: "path", b: true, s: true, r: true }
        end
      end

      context "without badged" do
        before { site.stub(badged: false) }

        it "includes b: false" do
          settings.hash.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: false, s: true, r: true }
        end
      end

      context "without ssl (free plan)" do
        before { site.stub(in_free_plan?: true) }

        it "doesn't include ssl key/value" do
          settings.hash.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: true, r: true }
        end
      end

      context "without realtime data (free plan)" do
        before { site.stub(plan_stats_retention_days: 0) }

        it "doesn't includes r key/value" do
          settings.hash.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: true, s: true }
        end
      end
    end
  end

end
