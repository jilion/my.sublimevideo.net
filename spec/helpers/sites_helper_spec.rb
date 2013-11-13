require 'spec_helper'

describe SitesHelper do

  describe "#sublimevideo_script_tag_for" do
    it "is should generate sublimevideo script_tag" do
      site = double(token: 'abcd1234')
      expect(helper.sublimevideo_script_tag_for(site)).to eq "<script type=\"text/javascript\" src=\"//cdn.sublimevideo.net/js/abcd1234.js\"></script>"
    end
  end

  describe "#hostname_or_token" do
    context "site with a hostname" do
      let(:site) { double(hostname: 'rymai.me') }

      it { expect(helper.hostname_or_token(site)).to eq 'rymai.me' }
      it { expect(helper.hostname_or_token(site, length: 5)).to eq "ry...e" }
    end

    context "site without a hostname" do
      let(:site) { double(hostname: '', token: 'abcd1234') }

      it { expect(helper.hostname_or_token(site)).to eq "#abcd1234" }
      it { expect(helper.hostname_or_token(site, prefix: 'FOO ')).to eq "FOO abcd1234" }
    end
  end

  describe "#hostname_with_path_needed & #need_path?" do
    context "with web.me.com hostname" do
      let(:site) { double(path?: false, hostname: 'web.me.com', extra_hostnames: nil) }

      it { expect(helper.hostname_with_path_needed(site)).to eq 'web.me.com' }
      it { expect(helper.need_path?(site)).to be_truthy }
    end

    context "with homepage.mac.com, web.me.com extra hostnames" do
      let(:site) { double(path?: false, hostname: 'rymai.me', extra_hostnames: 'homepage.mac.com, web.me.com') }

      it { expect(helper.hostname_with_path_needed(site)).to eq 'web.me.com' }
      it { expect(helper.need_path?(site)).to be_truthy }
    end

    context "with web.me.com hostname & path" do
      let(:site) { double(path?: true, hostname: 'web.me.com', extra_hostnames: nil) }

      it { expect(helper.hostname_with_path_needed(site)).to be_nil }
      it { expect(helper.need_path?(site)).to be_falsey }
    end

    context "with nothing special" do
      let(:site) { double(path?: false, hostname: 'rymai.me', extra_hostnames: nil) }

      it { expect(helper.hostname_with_path_needed(site)).to be_nil }
      it { expect(helper.need_path?(site)).to be_falsey }
    end
  end

  describe "#hostname_with_subdomain_needed & #need_subdomain?" do
    context "with tumblr.com hostname" do
      let(:site) { double(wildcard?: true, production_hostnames: %w[tumblr.com]) }

      it { expect(helper.hostname_with_subdomain_needed(site)).to eq 'tumblr.com' }
      it { expect(helper.need_subdomain?(site)).to be_truthy }
    end

    context "with tumblr.com extra hostnames" do
      let(:site) { double(wildcard?: true, production_hostnames: %w[rymai.me web.mac.com tumblr.com]) }

      it { expect(helper.hostname_with_subdomain_needed(site)).to eq 'tumblr.com' }
      it { expect(helper.need_subdomain?(site)).to be_truthy }
    end

    context "with wildcard only" do
      let(:site) { double(wildcard?: true, production_hostnames: %w[rymai.me]) }

      it { expect(helper.hostname_with_subdomain_needed(site)).to be_nil }
      it { expect(helper.need_subdomain?(site)).to be_falsey }
    end

    context "without wildcard" do
      let(:site) { double(wildcard?: false, production_hostnames: %w[tumblr.com]) }

      it { expect(helper.hostname_with_subdomain_needed(site)).to be_nil }
      it { expect(helper.need_subdomain?(site)).to be_falsey }
    end
  end

  describe "#s3_hostname_with_subdomain_needed & #need_s3_subdomain?" do
    context "with amazonaws.com hostname with wildcard" do
      let(:site) { double(wildcard?: true, production_hostnames: %w[s3.amazonaws.com]) }

      it { expect(helper.s3_hostname_with_subdomain_needed(site)).to eq 's3.amazonaws.com' }
      it { expect(helper.need_s3_subdomain?(site)).to be_truthy }
    end

    context "with amazonaws.com hostname without wildcard" do
      let(:site) { double(wildcard?: false, production_hostnames: %w[s3-us-west-2.amazonaws.com]) }

      it { expect(helper.s3_hostname_with_subdomain_needed(site)).to eq 's3-us-west-2.amazonaws.com' }
      it { expect(helper.need_s3_subdomain?(site)).to be_truthy }
    end

    context "with amazonaws.com extra hostnames with wildcard" do
      let(:site) { double(wildcard?: true, production_hostnames: %w[rymai.me web.mac.com s3-ap-southeast-1.amazonaws.com]) }

      it { expect(helper.s3_hostname_with_subdomain_needed(site)).to eq 's3-ap-southeast-1.amazonaws.com' }
      it { expect(helper.need_s3_subdomain?(site)).to be_truthy }
    end

    context "with amazonaws.com extra hostnames without wildcard" do
      let(:site) { double(wildcard?: false, production_hostnames: %w[rymai.me web.mac.com s3-fips-us-gov-west-1.amazonaws.com]) }

      it { expect(helper.s3_hostname_with_subdomain_needed(site)).to eq 's3-fips-us-gov-west-1.amazonaws.com' }
      it { expect(helper.need_s3_subdomain?(site)).to be_truthy }
    end
  end

end
