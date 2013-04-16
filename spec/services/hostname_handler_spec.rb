# coding: utf-8
require 'fast_spec_helper'
require 'active_support/core_ext'
require 'public_suffix'

require 'services/hostname_handler'

describe HostnameHandler do
  subject { HostnameHandler }

  describe "clean" do
    it { subject.clean(nil).should == nil }
    it { subject.clean("").should == "" }
    it { subject.clean("éCOLE").should == "école" }
    it { subject.clean("éCOLE.fr").should == "école.fr" }
    it { subject.clean("http://www.école.fr").should == "école.fr" }
    it { subject.clean("http://www.école.fr/super.html").should == "école.fr" }
    it { subject.clean("http://www.école.fr?super=cool").should == "école.fr" }
    it { subject.clean(".com").should == "com" }
    it { subject.clean("co.uk").should == "co.uk" }
    it { subject.clean("*.com").should == "*.com" }
    it { subject.clean("www.*.com").should == "*.com" }
    it { subject.clean("*").should == "*" }
    it { subject.clean(".").should == "." }
    it { subject.clean("ASDASD.COM").should == "asdasd.com" }
    it { subject.clean("124.123.151.123").should == "124.123.151.123" }
    it { subject.clean("124.123.151.123?super=cool").should == "124.123.151.123" }
    it { subject.clean("広告掲載.jp").should == "広告掲載.jp" }
    it { subject.clean("http://www.youtube.com?v=31231").should == "youtube.com" }
    it { subject.clean("web.me.com/super.fun").should == "web.me.com" }
    it { subject.clean("web.me.com/super.html").should == "web.me.com" }
    it { subject.clean("http://www.www.com").should == "www.com" }
    it { subject.clean("www.com").should == "www.com" }
    it { subject.clean("ftp://www.www.com").should == "www.com" }
    it { subject.clean("https://www.co.uk").should == "www.co.uk" }
    it { subject.clean("localhost").should == "localhost" }
    it { subject.clean("www").should == "www" }
    it { subject.clean("test;ERR").should == "test;err" }
    it { subject.clean("http://test;ERR").should == "test;err" }
    it { subject.clean("http://www.localhost:3000").should == "localhost" }
    it { subject.clean("ftp://127.]boo[:3000").should == "127.]boo[" }
    it { subject.clean("www.joke;foo").should == "joke;foo" }
    it { subject.clean("localhost:3000,,http://www.bob.com").should == "bob.com, localhost" }
  end

  describe "valid?" do
    it { subject.main_invalid?("*.google.com").should be_false }
    it { subject.main_invalid?("éCOLE.fr").should be_false }
    it { subject.main_invalid?("ASDASD.COM").should be_false }
    it { subject.main_invalid?("広告掲載.jp").should be_false }
    it { subject.main_invalid?("http://www.youtube.com?v=31231").should be_false }
    it { subject.main_invalid?("http://www.www.com").should be_false }
    it { subject.main_invalid?("www.com").should be_false }
    it { subject.main_invalid?("ftp://www.www.com").should be_false }
    it { subject.main_invalid?("https://www.co.uk").should be_false }
    it { subject.main_invalid?("124.123.151.123").should be_false }
    it { subject.main_invalid?("blogspot.com").should be_false }
    it { subject.main_invalid?("appspot.com").should be_false }
    it { subject.main_invalid?("operaunite.com").should be_false }
    it { subject.main_invalid?("еаои.рф").should be_false }
    it { subject.main_invalid?("pepe.pm").should be_false }

    it { subject.main_invalid?("3ffe:505:2::1").should be_true } # ipv6
    it { subject.main_invalid?("127.0.0.1").should be_true }
    it { subject.main_invalid?("0.0.0.0").should be_true }
    it { subject.main_invalid?("google.local").should be_true }
    it { subject.main_invalid?(nil).should be_true }
    it { subject.main_invalid?("").should be_true }
    it { subject.main_invalid?(".com").should be_true }
    it { subject.main_invalid?("co.uk").should be_true }
    it { subject.main_invalid?("www").should be_true }
    it { subject.main_invalid?("*").should be_true }
    it { subject.main_invalid?("*.*").should be_true }
    it { subject.main_invalid?("éCOLE").should be_true }
    it { subject.main_invalid?("localhost").should be_true }
    it { subject.main_invalid?("com").should be_true }
    it { subject.main_invalid?("test;ERR").should be_true }
    it { subject.main_invalid?("http://test;ERR").should be_true }
    it { subject.main_invalid?("http://www.localhost:3000").should be_true }
    it { subject.main_invalid?("ftp://127.]boo[:3000").should be_true }
    it { subject.main_invalid?("www.joke;foo").should be_true }
    it { subject.main_invalid?("http://www.bob.com,,localhost:3000").should be_true }
  end

  describe "extra_valid?" do
    it { subject.extra_invalid?(nil).should be_false }
    it { subject.extra_invalid?("").should be_false }
    it { subject.extra_invalid?("*.google.com").should be_false }
    it { subject.extra_invalid?("éCOLE.fr").should be_false }
    it { subject.extra_invalid?("ASDASD.COM").should be_false }
    it { subject.extra_invalid?("jilion.org, jilion.net").should be_false }
    it { subject.extra_invalid?("広告掲載.jp").should be_false }
    it { subject.extra_invalid?("http://www.youtube.com?v=31231").should be_false }
    it { subject.extra_invalid?("http://www.www.com").should be_false }
    it { subject.extra_invalid?("www.com").should be_false }
    it { subject.extra_invalid?("ftp://www.www.com").should be_false }
    it { subject.extra_invalid?("https://www.co.uk").should be_false }
    it { subject.extra_invalid?("124.123.151.123").should be_false }
    it { subject.extra_invalid?("blogspot.com").should be_false }
    it { subject.extra_invalid?("appspot.com").should be_false }
    it { subject.extra_invalid?("operaunite.com").should be_false }

    it { subject.extra_invalid?("3ffe:505:2::1").should be_true } # ipv6
    it { subject.extra_invalid?("127.0.0.1").should be_true }
    it { subject.extra_invalid?("0.0.0.0").should be_true }
    it { subject.extra_invalid?("google.local").should be_true }
    it { subject.extra_invalid?(".com").should be_true }
    it { subject.extra_invalid?("co.uk").should be_true }
    it { subject.extra_invalid?("www").should be_true }
    it { subject.extra_invalid?("*").should be_true }
    it { subject.extra_invalid?("*.*").should be_true }
    it { subject.extra_invalid?("éCOLE").should be_true }
    it { subject.extra_invalid?("localhost").should be_true }
    it { subject.extra_invalid?("com").should be_true }
    it { subject.extra_invalid?("test;ERR").should be_true }
    it { subject.extra_invalid?("http://test;ERR").should be_true }
    it { subject.extra_invalid?("http://www.localhost:3000").should be_true }
    it { subject.extra_invalid?("ftp://127.]boo[:3000").should be_true }
    it { subject.extra_invalid?("www.joke;foo").should be_true }
    it { subject.extra_invalid?("http://www.bob.com,,localhost:3000").should be_true }
  end

  describe "dev_valid?" do
    it { subject.dev_invalid?(nil).should be_false }
    it { subject.dev_invalid?("").should be_false }
    it { subject.dev_invalid?("127.0.0.1").should be_false }
    it { subject.dev_invalid?("10.0.0.0").should be_false }
    it { subject.dev_invalid?("10.0.0.30").should be_false }
    it { subject.dev_invalid?("10.255.255.255").should be_false }
    it { subject.dev_invalid?("172.16.0.0").should be_false }
    it { subject.dev_invalid?("172.16.0.30").should be_false }
    it { subject.dev_invalid?("172.31.255.255").should be_false }
    it { subject.dev_invalid?("192.168.0.0").should be_false }
    it { subject.dev_invalid?("192.168.0.30").should be_false }
    it { subject.dev_invalid?("192.168.255.255").should be_false }
    it { subject.dev_invalid?("0.0.0.0").should be_false }
    it { subject.dev_invalid?("google.local").should be_false }
    it { subject.dev_invalid?("localhost").should be_false }
    it { subject.dev_invalid?("localhost:8888").should be_false }
    it { subject.dev_invalid?("google.prod").should be_false }
    it { subject.dev_invalid?("google.dev").should be_false }
    it { subject.dev_invalid?("google.test").should be_false }
    it { subject.dev_invalid?("http://www.localhost:3000").should be_false }
    it { subject.dev_invalid?("www").should be_false }
    it { subject.dev_invalid?("co.uk").should be_false }
    it { subject.dev_invalid?("com").should be_false }

    it { subject.dev_invalid?("éCOLE").should be_false }
    it { subject.dev_invalid?("test;ERR").should be_false }
    it { subject.dev_invalid?("http://test;ERR").should be_false }
    it { subject.dev_invalid?("www.joke;foo").should be_false }
    it { subject.dev_invalid?("ftp://127.]boo[:3000").should be_false }
    it { subject.dev_invalid?("*.*").should be_false }
    it { subject.dev_invalid?("*").should be_false }
    it { subject.dev_invalid?(".com").should be_false }

    it { subject.dev_invalid?("124.123.151.123").should be_true }
    it { subject.dev_invalid?("11.0.0.0").should be_true }
    it { subject.dev_invalid?("172.32.0.0").should be_true }
    it { subject.dev_invalid?("192.169.0.0").should be_true }
    it { subject.dev_invalid?("http://www.bob.com,,localhost:3000").should be_true }
    it { subject.dev_invalid?("*.google.com").should be_true }
    it { subject.dev_invalid?("staging.google.com").should be_true }
    it { subject.dev_invalid?("test.google.com").should be_true }
    it { subject.dev_invalid?("éCOLE.fr").should be_true }
    it { subject.dev_invalid?("ASDASD.COM").should be_true }
    it { subject.dev_invalid?("広告掲載.jp").should be_true }
    it { subject.dev_invalid?("http://www.youtube.com?v=31231").should be_true }
    it { subject.dev_invalid?("http://www.www.com").should be_true }
    it { subject.dev_invalid?("www.com").should be_true }
    it { subject.dev_invalid?("ftp://www.www.com").should be_true }
    it { subject.dev_invalid?("https://www.co.uk").should be_true }
  end

  describe "wildcard?" do
    it { subject.wildcard?("*.com").should be_true }
    it { subject.wildcard?("www.*.com").should be_true }
    it { subject.wildcard?("bob.*.com").should be_true }
    it { subject.wildcard?("*").should be_true }
    it { subject.wildcard?("*.*").should be_true }
    it { subject.wildcard?("*.google.com").should be_true }
    it { subject.wildcard?("google.fr, *.google.com").should be_true }

    it { subject.wildcard?(nil).should be_false }
    it { subject.wildcard?("").should be_false }
    it { subject.wildcard?("co.uk").should be_false }
    it { subject.wildcard?("localhost").should be_false }
    it { subject.wildcard?("google.fr").should be_false }
  end

  describe "duplicate?" do
    it { subject.duplicate?("http://localhost:3000, localhost").should be_true }
    it { subject.duplicate?("http://www.localhost:3000, localhost").should be_true }
    it { subject.duplicate?("127.0.0.1, bob, 127.0.0.1").should be_true }
    it { subject.duplicate?("*.*, *.*").should be_true }
    it { subject.duplicate?("*, *").should be_true }
    it { subject.duplicate?("google.fr, google.fr").should be_true }

    it { subject.duplicate?(nil).should be_false }
    it { subject.duplicate?("").should be_false }
    it { subject.duplicate?("localhost").should be_false }
    it { subject.duplicate?("bob.fr, bob.com").should be_false }
    it { subject.duplicate?("google.fr, staging.google.fr").should be_false }
  end

  describe "include?" do
    it { subject.include_hostname?('http://localhost:3000, localhost', stub(hostname: 'localhost')).should be_true }
    it { subject.include_hostname?('124.123.151.123, localhost', stub(hostname: '124.123.151.123')).should be_true }
    it { subject.include_hostname?('127.0.0.1, bob, 127.0.0.1', stub(hostname: 'bob')).should be_true }
    it { subject.include_hostname?('*.*, *.*', stub(hostname: '*.*')).should be_true }
    it { subject.include_hostname?('google.fr, jilion.com', stub(hostname: 'google.fr')).should be_true }

    it { subject.include_hostname?(nil, stub(hostname: 'jilion.com')).should be_false }
    it { subject.include_hostname?('jilion.com', nil).should be_false }
    it { subject.include_hostname?('jilion.com', stub(hostname: nil)).should be_false }
    it { subject.include_hostname?('jilion.com', stub(hostname: '')).should be_false }
    it { subject.include_hostname?(nil, nil).should be_false }
    it { subject.include_hostname?(nil, stub(hostname: nil)).should be_false }
    it { subject.include_hostname?('', stub(hostname: '')).should be_false }
    it { subject.include_hostname?('', stub(hostname: 'jilion.com')).should be_false }
    it { subject.include_hostname?('localhost, jilion', stub(hostname: 'jilion.com')).should be_false }
  end

end
