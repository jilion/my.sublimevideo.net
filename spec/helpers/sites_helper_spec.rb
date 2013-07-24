require 'spec_helper'

describe SitesHelper do

  describe "#sublimevideo_script_tag_for" do
    it "is should generate sublimevideo script_tag" do
      site = stub(token: 'abcd1234')
      helper.sublimevideo_script_tag_for(site).should eq "<script type=\"text/javascript\" src=\"//cdn.sublimevideo.net/js/abcd1234.js\"></script>"
    end
  end

  describe "#hostname_or_token" do
    context "site with a hostname" do
      let(:site) { stub(hostname: 'rymai.me') }

      it { helper.hostname_or_token(site).should eq 'rymai.me' }
      it { helper.hostname_or_token(site, length: 5).should eq "ry...e" }
    end

    context "site without a hostname" do
      let(:site) { stub(hostname: '', token: 'abcd1234') }

      it { helper.hostname_or_token(site).should eq "#abcd1234" }
      it { helper.hostname_or_token(site, prefix: 'FOO ').should eq "FOO abcd1234" }
    end
  end

  describe "#hostname_with_path_needed & #need_path?" do
    context "with web.me.com hostname" do
      let(:site) { stub(path?: false, hostname: 'web.me.com', extra_hostnames: nil) }

      it { helper.hostname_with_path_needed(site).should eq 'web.me.com' }
      it { helper.need_path?(site).should be_true }
    end

    context "with homepage.mac.com, web.me.com extra hostnames" do
      let(:site) { stub(path?: false, hostname: 'rymai.me', extra_hostnames: 'homepage.mac.com, web.me.com') }

      it { helper.hostname_with_path_needed(site).should eq 'web.me.com' }
      it { helper.need_path?(site).should be_true }
    end

    context "with web.me.com hostname & path" do
      let(:site) { stub(path?: true, hostname: 'web.me.com', extra_hostnames: nil) }

      it { helper.hostname_with_path_needed(site).should be_nil }
      it { helper.need_path?(site).should be_false }
    end

    context "with nothing special" do
      let(:site) { stub(path?: false, hostname: 'rymai.me', extra_hostnames: nil) }

      it { helper.hostname_with_path_needed(site).should be_nil }
      it { helper.need_path?(site).should be_false }
    end
  end

  describe "#hostname_with_subdomain_needed & #need_subdomain?" do
    context "with tumblr.com hostname" do
      let(:site) { stub(wildcard?: true, production_hostnames: %w[tumblr.com]) }

      it { helper.hostname_with_subdomain_needed(site).should eq 'tumblr.com' }
      it { helper.need_subdomain?(site).should be_true }
    end

    context "with tumblr.com extra hostnames" do
      let(:site) { stub(wildcard?: true, production_hostnames: %w[rymai.me web.mac.com tumblr.com]) }

      it { helper.hostname_with_subdomain_needed(site).should eq 'tumblr.com' }
      it { helper.need_subdomain?(site).should be_true }
    end

    context "with wildcard only" do
      let(:site) { stub(wildcard?: true, production_hostnames: %w[rymai.me]) }

      it { helper.hostname_with_subdomain_needed(site).should be_nil }
      it { helper.need_subdomain?(site).should be_false }
    end

    context "without wildcard" do
      let(:site) { stub(wildcard?: false, production_hostnames: %w[tumblr.com]) }

      it { helper.hostname_with_subdomain_needed(site).should be_nil }
      it { helper.need_subdomain?(site).should be_false }
    end
  end

  describe "#s3_hostname_with_subdomain_needed & #need_s3_subdomain?" do
    context "with amazonaws.com hostname with wildcard" do
      let(:site) { stub(wildcard?: true, production_hostnames: %w[s3.amazonaws.com]) }

      it { helper.s3_hostname_with_subdomain_needed(site).should eq 's3.amazonaws.com' }
      it { helper.need_s3_subdomain?(site).should be_true }
    end

    context "with amazonaws.com hostname without wildcard" do
      let(:site) { stub(wildcard?: false, production_hostnames: %w[s3-us-west-2.amazonaws.com]) }

      it { helper.s3_hostname_with_subdomain_needed(site).should eq 's3-us-west-2.amazonaws.com' }
      it { helper.need_s3_subdomain?(site).should be_true }
    end

    context "with amazonaws.com extra hostnames with wildcard" do
      let(:site) { stub(wildcard?: true, production_hostnames: %w[rymai.me web.mac.com s3-ap-southeast-1.amazonaws.com]) }

      it { helper.s3_hostname_with_subdomain_needed(site).should eq 's3-ap-southeast-1.amazonaws.com' }
      it { helper.need_s3_subdomain?(site).should be_true }
    end

    context "with amazonaws.com extra hostnames without wildcard" do
      let(:site) { stub(wildcard?: false, production_hostnames: %w[rymai.me web.mac.com s3-fips-us-gov-west-1.amazonaws.com]) }

      it { helper.s3_hostname_with_subdomain_needed(site).should eq 's3-fips-us-gov-west-1.amazonaws.com' }
      it { helper.need_s3_subdomain?(site).should be_true }
    end
  end

end
