# coding: utf-8
require 'fast_spec_helper'
require 'active_support/core_ext'
require 'public_suffix'

require 'services/hostname_handler'

describe HostnameHandler do
  subject { HostnameHandler }

  describe "clean" do
    it { expect(subject.clean(nil)).to eq nil }
    it { expect(subject.clean("")).to eq "" }
    it { expect(subject.clean("éCOLE")).to eq "école" }
    it { expect(subject.clean("éCOLE.fr")).to eq "école.fr" }
    it { expect(subject.clean("http://www.école.fr")).to eq "école.fr" }
    it { expect(subject.clean("http://www.école.fr/super.html")).to eq "école.fr" }
    it { expect(subject.clean("http://www.école.fr?super=cool")).to eq "école.fr" }
    it { expect(subject.clean(".com")).to eq "com" }
    it { expect(subject.clean("co.uk")).to eq "co.uk" }
    it { expect(subject.clean("*.com")).to eq "*.com" }
    it { expect(subject.clean("www.*.com")).to eq "*.com" }
    it { expect(subject.clean("*")).to eq "*" }
    it { expect(subject.clean(".")).to eq "." }
    it { expect(subject.clean("ASDASD.COM")).to eq "asdasd.com" }
    it { expect(subject.clean("124.123.151.123")).to eq "124.123.151.123" }
    it { expect(subject.clean("124.123.151.123?super=cool")).to eq "124.123.151.123" }
    it { expect(subject.clean("広告掲載.jp")).to eq "広告掲載.jp" }
    it { expect(subject.clean("http://www.youtube.com?v=31231")).to eq "youtube.com" }
    it { expect(subject.clean("web.me.com/super.fun")).to eq "web.me.com" }
    it { expect(subject.clean("web.me.com/super.html")).to eq "web.me.com" }
    it { expect(subject.clean("http://www.www.com")).to eq "www.com" }
    it { expect(subject.clean("www.com")).to eq "www.com" }
    it { expect(subject.clean("ftp://www.www.com")).to eq "www.com" }
    it { expect(subject.clean("https://www.co.uk")).to eq "www.co.uk" }
    it { expect(subject.clean("localhost")).to eq "localhost" }
    it { expect(subject.clean("www")).to eq "www" }
    it { expect(subject.clean("test;ERR")).to eq "test;err" }
    it { expect(subject.clean("http://test;ERR")).to eq "test;err" }
    it { expect(subject.clean("http://www.localhost:3000")).to eq "localhost" }
    it { expect(subject.clean("ftp://127.]boo[:3000")).to eq "127.]boo[" }
    it { expect(subject.clean("www.joke;foo")).to eq "joke;foo" }
    it { expect(subject.clean("localhost:3000,,http://www.bob.com")).to eq "bob.com, localhost" }
    it { expect(subject.clean('<script type="text/javascript" src="//cdn.sublimevideo.net/js/abcd1234.js"></script>enontab.org')).to eq '&lt;script type=&quot;text/javascript&quot; src=&quot;//cdn.sublimevideo.net/js/abcd1234.js&quot;&gt;&lt;/script&gt;enontab.org' }
  end

  describe "main_invalid?" do
    it { expect(subject.main_invalid?("*.google.com")).to be_falsey }
    it { expect(subject.main_invalid?("éCOLE.fr")).to be_falsey }
    it { expect(subject.main_invalid?("ASDASD.COM")).to be_falsey }
    it { expect(subject.main_invalid?("広告掲載.jp")).to be_falsey }
    it { expect(subject.main_invalid?("http://www.youtube.com?v=31231")).to be_falsey }
    it { expect(subject.main_invalid?("http://www.www.com")).to be_falsey }
    it { expect(subject.main_invalid?("www.com")).to be_falsey }
    it { expect(subject.main_invalid?("ftp://www.www.com")).to be_falsey }
    it { expect(subject.main_invalid?("https://www.co.uk")).to be_falsey }
    it { expect(subject.main_invalid?("124.123.151.123")).to be_falsey }
    it { expect(subject.main_invalid?("blogspot.com")).to be_falsey }
    it { expect(subject.main_invalid?("appspot.com")).to be_falsey }
    it { expect(subject.main_invalid?("operaunite.com")).to be_falsey }
    it { expect(subject.main_invalid?("еаои.рф")).to be_falsey }
    it { expect(subject.main_invalid?("pepe.pm")).to be_falsey }

    it { expect(subject.main_invalid?("3ffe:505:2::1")).to be_truthy } # ipv6
    it { expect(subject.main_invalid?("127.0.0.1")).to be_truthy }
    it { expect(subject.main_invalid?("0.0.0.0")).to be_truthy }
    it { expect(subject.main_invalid?("google.local")).to be_truthy }
    it { expect(subject.main_invalid?(nil)).to be_truthy }
    it { expect(subject.main_invalid?("")).to be_truthy }
    it { expect(subject.main_invalid?(".com")).to be_truthy }
    it { expect(subject.main_invalid?("co.uk")).to be_truthy }
    it { expect(subject.main_invalid?("www")).to be_truthy }
    it { expect(subject.main_invalid?("*")).to be_truthy }
    it { expect(subject.main_invalid?("*.*")).to be_truthy }
    it { expect(subject.main_invalid?("éCOLE")).to be_truthy }
    it { expect(subject.main_invalid?("localhost")).to be_truthy }
    it { expect(subject.main_invalid?("com")).to be_truthy }
    it { expect(subject.main_invalid?("test;ERR")).to be_truthy }
    it { expect(subject.main_invalid?("http://test;ERR")).to be_truthy }
    it { expect(subject.main_invalid?("http://www.localhost:3000")).to be_truthy }
    it { expect(subject.main_invalid?("ftp://127.]boo[:3000")).to be_truthy }
    it { expect(subject.main_invalid?("www.joke;foo")).to be_truthy }
    it { expect(subject.main_invalid?("http://www.bob.com,,localhost:3000")).to be_truthy }

    it { expect(subject.main_invalid?("s3.amazonaws.com")).to be_truthy }
    it { expect(subject.main_invalid?("s3-us-gov-west-1.amazonaws.com")).to be_truthy }
    it { expect(subject.main_invalid?("subdomain.s3.amazonaws.com")).to be_falsey }
  end

  describe "extra_invalid?" do
    it { expect(subject.extra_invalid?(nil)).to be_falsey }
    it { expect(subject.extra_invalid?("")).to be_falsey }
    it { expect(subject.extra_invalid?("*.google.com")).to be_falsey }
    it { expect(subject.extra_invalid?("éCOLE.fr")).to be_falsey }
    it { expect(subject.extra_invalid?("ASDASD.COM")).to be_falsey }
    it { expect(subject.extra_invalid?("jilion.org, jilion.net")).to be_falsey }
    it { expect(subject.extra_invalid?("広告掲載.jp")).to be_falsey }
    it { expect(subject.extra_invalid?("http://www.youtube.com?v=31231")).to be_falsey }
    it { expect(subject.extra_invalid?("http://www.www.com")).to be_falsey }
    it { expect(subject.extra_invalid?("www.com")).to be_falsey }
    it { expect(subject.extra_invalid?("ftp://www.www.com")).to be_falsey }
    it { expect(subject.extra_invalid?("https://www.co.uk")).to be_falsey }
    it { expect(subject.extra_invalid?("124.123.151.123")).to be_falsey }
    it { expect(subject.extra_invalid?("blogspot.com")).to be_falsey }
    it { expect(subject.extra_invalid?("appspot.com")).to be_falsey }
    it { expect(subject.extra_invalid?("operaunite.com")).to be_falsey }

    it { expect(subject.extra_invalid?("3ffe:505:2::1")).to be_truthy } # ipv6
    it { expect(subject.extra_invalid?("127.0.0.1")).to be_truthy }
    it { expect(subject.extra_invalid?("0.0.0.0")).to be_truthy }
    it { expect(subject.extra_invalid?("google.local")).to be_truthy }
    it { expect(subject.extra_invalid?(".com")).to be_truthy }
    it { expect(subject.extra_invalid?("co.uk")).to be_truthy }
    it { expect(subject.extra_invalid?("www")).to be_truthy }
    it { expect(subject.extra_invalid?("*")).to be_truthy }
    it { expect(subject.extra_invalid?("*.*")).to be_truthy }
    it { expect(subject.extra_invalid?("éCOLE")).to be_truthy }
    it { expect(subject.extra_invalid?("localhost")).to be_truthy }
    it { expect(subject.extra_invalid?("com")).to be_truthy }
    it { expect(subject.extra_invalid?("test;ERR")).to be_truthy }
    it { expect(subject.extra_invalid?("http://test;ERR")).to be_truthy }
    it { expect(subject.extra_invalid?("http://www.localhost:3000")).to be_truthy }
    it { expect(subject.extra_invalid?("ftp://127.]boo[:3000")).to be_truthy }
    it { expect(subject.extra_invalid?("www.joke;foo")).to be_truthy }
    it { expect(subject.extra_invalid?("http://www.bob.com,,localhost:3000")).to be_truthy }

    it { expect(subject.extra_invalid?("s3.amazonaws.com")).to be_truthy }
    it { expect(subject.extra_invalid?("s3-us-gov-west-1.amazonaws.com")).to be_truthy }
    it { expect(subject.extra_invalid?("subdomain.s3.amazonaws.com")).to be_falsey }
  end

  describe "dev_invalid?" do
    it { expect(subject.dev_invalid?(nil)).to be_falsey }
    it { expect(subject.dev_invalid?("")).to be_falsey }
    it { expect(subject.dev_invalid?("127.0.0.1")).to be_falsey }
    it { expect(subject.dev_invalid?("10.0.0.0")).to be_falsey }
    it { expect(subject.dev_invalid?("10.0.0.30")).to be_falsey }
    it { expect(subject.dev_invalid?("10.255.255.255")).to be_falsey }
    it { expect(subject.dev_invalid?("172.16.0.0")).to be_falsey }
    it { expect(subject.dev_invalid?("172.16.0.30")).to be_falsey }
    it { expect(subject.dev_invalid?("172.31.255.255")).to be_falsey }
    it { expect(subject.dev_invalid?("192.168.0.0")).to be_falsey }
    it { expect(subject.dev_invalid?("192.168.0.30")).to be_falsey }
    it { expect(subject.dev_invalid?("192.168.255.255")).to be_falsey }
    it { expect(subject.dev_invalid?("0.0.0.0")).to be_falsey }
    it { expect(subject.dev_invalid?("google.local")).to be_falsey }
    it { expect(subject.dev_invalid?("localhost")).to be_falsey }
    it { expect(subject.dev_invalid?("localhost:8888")).to be_falsey }
    it { expect(subject.dev_invalid?("google.prod")).to be_falsey }
    it { expect(subject.dev_invalid?("google.dev")).to be_falsey }
    it { expect(subject.dev_invalid?("google.test")).to be_falsey }
    it { expect(subject.dev_invalid?("http://www.localhost:3000")).to be_falsey }
    it { expect(subject.dev_invalid?("www")).to be_falsey }
    it { expect(subject.dev_invalid?("co.uk")).to be_falsey }
    it { expect(subject.dev_invalid?("com")).to be_falsey }

    it { expect(subject.dev_invalid?("éCOLE")).to be_falsey }
    it { expect(subject.dev_invalid?("test;ERR")).to be_falsey }
    it { expect(subject.dev_invalid?("http://test;ERR")).to be_falsey }
    it { expect(subject.dev_invalid?("www.joke;foo")).to be_falsey }
    it { expect(subject.dev_invalid?("ftp://127.]boo[:3000")).to be_falsey }
    it { expect(subject.dev_invalid?("*.*")).to be_falsey }
    it { expect(subject.dev_invalid?("*")).to be_falsey }
    it { expect(subject.dev_invalid?(".com")).to be_falsey }

    it { expect(subject.dev_invalid?("124.123.151.123")).to be_truthy }
    it { expect(subject.dev_invalid?("11.0.0.0")).to be_truthy }
    it { expect(subject.dev_invalid?("172.32.0.0")).to be_truthy }
    it { expect(subject.dev_invalid?("192.169.0.0")).to be_truthy }
    it { expect(subject.dev_invalid?("http://www.bob.com,,localhost:3000")).to be_truthy }
    it { expect(subject.dev_invalid?("*.google.com")).to be_truthy }
    it { expect(subject.dev_invalid?("staging.google.com")).to be_truthy }
    it { expect(subject.dev_invalid?("test.google.com")).to be_truthy }
    it { expect(subject.dev_invalid?("éCOLE.fr")).to be_truthy }
    it { expect(subject.dev_invalid?("ASDASD.COM")).to be_truthy }
    it { expect(subject.dev_invalid?("広告掲載.jp")).to be_truthy }
    it { expect(subject.dev_invalid?("http://www.youtube.com?v=31231")).to be_truthy }
    it { expect(subject.dev_invalid?("http://www.www.com")).to be_truthy }
    it { expect(subject.dev_invalid?("www.com")).to be_truthy }
    it { expect(subject.dev_invalid?("ftp://www.www.com")).to be_truthy }
    it { expect(subject.dev_invalid?("https://www.co.uk")).to be_truthy }

    it { expect(subject.dev_invalid?("s3.amazonaws.com")).to be_falsey }
    it { expect(subject.dev_invalid?("s3-us-gov-west-1.amazonaws.com")).to be_falsey }
    it { expect(subject.dev_invalid?("subdomain.s3.amazonaws.com")).to be_truthy }
  end

  describe "wildcard?" do
    it { expect(subject.wildcard?("*.com")).to be_truthy }
    it { expect(subject.wildcard?("www.*.com")).to be_truthy }
    it { expect(subject.wildcard?("bob.*.com")).to be_truthy }
    it { expect(subject.wildcard?("*")).to be_truthy }
    it { expect(subject.wildcard?("*.*")).to be_truthy }
    it { expect(subject.wildcard?("*.google.com")).to be_truthy }
    it { expect(subject.wildcard?("google.fr, *.google.com")).to be_truthy }

    it { expect(subject.wildcard?(nil)).to be_falsey }
    it { expect(subject.wildcard?("")).to be_falsey }
    it { expect(subject.wildcard?("co.uk")).to be_falsey }
    it { expect(subject.wildcard?("localhost")).to be_falsey }
    it { expect(subject.wildcard?("google.fr")).to be_falsey }
  end

  describe "duplicate?" do
    it { expect(subject.duplicate?("http://localhost:3000, localhost")).to be_truthy }
    it { expect(subject.duplicate?("http://www.localhost:3000, localhost")).to be_truthy }
    it { expect(subject.duplicate?("127.0.0.1, bob, 127.0.0.1")).to be_truthy }
    it { expect(subject.duplicate?("*.*, *.*")).to be_truthy }
    it { expect(subject.duplicate?("*, *")).to be_truthy }
    it { expect(subject.duplicate?("google.fr, google.fr")).to be_truthy }

    it { expect(subject.duplicate?(nil)).to be_falsey }
    it { expect(subject.duplicate?("")).to be_falsey }
    it { expect(subject.duplicate?("localhost")).to be_falsey }
    it { expect(subject.duplicate?("bob.fr, bob.com")).to be_falsey }
    it { expect(subject.duplicate?("google.fr, staging.google.fr")).to be_falsey }
  end

  describe "include_hostname?" do
    it { expect(subject.include_hostname?('http://localhost:3000, localhost', double(hostname: 'localhost'))).to be_truthy }
    it { expect(subject.include_hostname?('124.123.151.123, localhost', double(hostname: '124.123.151.123'))).to be_truthy }
    it { expect(subject.include_hostname?('127.0.0.1, bob, 127.0.0.1', double(hostname: 'bob'))).to be_truthy }
    it { expect(subject.include_hostname?('*.*, *.*', double(hostname: '*.*'))).to be_truthy }
    it { expect(subject.include_hostname?('google.fr, jilion.com', double(hostname: 'google.fr'))).to be_truthy }

    it { expect(subject.include_hostname?(nil, double(hostname: 'jilion.com'))).to be_falsey }
    it { expect(subject.include_hostname?('jilion.com', double(hostname: nil))).to be_falsey }
    it { expect(subject.include_hostname?('jilion.com', double(hostname: ''))).to be_falsey }
    it { expect(subject.include_hostname?(nil, nil)).to be_falsey }
    it { expect(subject.include_hostname?(nil, double(hostname: nil))).to be_falsey }
    it { expect(subject.include_hostname?('', double(hostname: ''))).to be_falsey }
    it { expect(subject.include_hostname?('', double(hostname: 'jilion.com'))).to be_falsey }
    it { expect(subject.include_hostname?('localhost, jilion', double(hostname: 'jilion.com'))).to be_falsey }
  end

end
