require "fast_spec_helper"
require File.expand_path('lib/api/url')

describe Api::Url do

  context "development Rails.env" do
    before { Rails.stub(:env) { 'development' } }

    context "www subdomain" do
      subject { Api::Url.new('www') }
      its(:url) { should eq 'http://sublimevideo.dev/api' }
    end

    context "my subdomain" do
      subject { Api::Url.new('my') }
      its(:url) { should eq 'http://my.sublimevideo.dev/api' }
    end
  end

  context "production Rails.env" do
    before { Rails.stub(:env) { 'production' } }

    context "my subdomain" do
      subject { Api::Url.new('my') }
      its(:url) { should eq 'https://my.sublimevideo.net/api' }
    end
  end

  context "staging Rails.env" do
    before { Rails.stub(:env) { 'staging' } }

    context "my subdomain" do
      subject { Api::Url.new('my') }
      its(:url) { should eq 'https://my.sublimevideo-staging.net/api' }
    end
  end

  context "test Rails.env" do
    before { Rails.stub(:env) { 'test' } }

    context "www subdomain" do
      subject { Api::Url.new('my') }
      its(:url) { should eq 'http://localhost/api' }
    end

    context "my subdomain" do
      subject { Api::Url.new('my') }
      its(:url) { should eq 'http://localhost/api' }
    end
  end

end
