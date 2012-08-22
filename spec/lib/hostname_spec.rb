# coding: utf-8
require 'fast_spec_helper'
require 'public_suffix'
require File.expand_path('lib/hostname')

describe Hostname do
  subject { Hostname }

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
    it { subject.clean("localhost:3000,,http://www.bob.com").should == "bob.com,localhost" }
  end

  describe "valid?" do
    it { subject.valid?("*.google.com").should be_true }
    it { subject.valid?("éCOLE.fr").should be_true }
    it { subject.valid?("ASDASD.COM").should be_true }
    it { subject.valid?("広告掲載.jp").should be_true }
    it { subject.valid?("http://www.youtube.com?v=31231").should be_true }
    it { subject.valid?("http://www.www.com").should be_true }
    it { subject.valid?("www.com").should be_true }
    it { subject.valid?("ftp://www.www.com").should be_true }
    it { subject.valid?("https://www.co.uk").should be_true }
    it { subject.valid?("124.123.151.123").should be_true }
    it { subject.valid?("blogspot.com").should be_true }
    it { subject.valid?("appspot.com").should be_true }
    it { subject.valid?("operaunite.com").should be_true }
    it { subject.valid?("еаои.рф").should be_true }

    it { subject.valid?("3ffe:505:2::1").should be_false } # ipv6
    it { subject.valid?("127.0.0.1").should be_false }
    it { subject.valid?("0.0.0.0").should be_false }
    it { subject.valid?("google.local").should be_false }
    it { subject.valid?(nil).should be_false }
    it { subject.valid?("").should be_false }
    it { subject.valid?(".com").should be_false }
    it { subject.valid?("co.uk").should be_false }
    it { subject.valid?("www").should be_false }
    it { subject.valid?("*").should be_false }
    it { subject.valid?("*.*").should be_false }
    it { subject.valid?("éCOLE").should be_false }
    it { subject.valid?("localhost").should be_false }
    it { subject.valid?("com").should be_false }
    it { subject.valid?("test;ERR").should be_false }
    it { subject.valid?("http://test;ERR").should be_false }
    it { subject.valid?("http://www.localhost:3000").should be_false }
    it { subject.valid?("ftp://127.]boo[:3000").should be_false }
    it { subject.valid?("www.joke;foo").should be_false }
    it { subject.valid?("http://www.bob.com,,localhost:3000").should be_false }
  end

  describe "extra_valid?" do
    it { subject.extra_valid?(nil).should be_true }
    it { subject.extra_valid?("").should be_true }
    it { subject.extra_valid?("*.google.com").should be_true }
    it { subject.extra_valid?("éCOLE.fr").should be_true }
    it { subject.extra_valid?("ASDASD.COM").should be_true }
    it { subject.extra_valid?("jilion.org, jilion.net").should be_true }
    it { subject.extra_valid?("広告掲載.jp").should be_true }
    it { subject.extra_valid?("http://www.youtube.com?v=31231").should be_true }
    it { subject.extra_valid?("http://www.www.com").should be_true }
    it { subject.extra_valid?("www.com").should be_true }
    it { subject.extra_valid?("ftp://www.www.com").should be_true }
    it { subject.extra_valid?("https://www.co.uk").should be_true }
    it { subject.extra_valid?("124.123.151.123").should be_true }
    it { subject.extra_valid?("blogspot.com").should be_true }
    it { subject.extra_valid?("appspot.com").should be_true }
    it { subject.extra_valid?("operaunite.com").should be_true }

    it { subject.extra_valid?("3ffe:505:2::1").should be_false } # ipv6
    it { subject.extra_valid?("127.0.0.1").should be_false }
    it { subject.extra_valid?("0.0.0.0").should be_false }
    it { subject.extra_valid?("google.local").should be_false }
    it { subject.extra_valid?(".com").should be_false }
    it { subject.extra_valid?("co.uk").should be_false }
    it { subject.extra_valid?("www").should be_false }
    it { subject.extra_valid?("*").should be_false }
    it { subject.extra_valid?("*.*").should be_false }
    it { subject.extra_valid?("éCOLE").should be_false }
    it { subject.extra_valid?("localhost").should be_false }
    it { subject.extra_valid?("com").should be_false }
    it { subject.extra_valid?("test;ERR").should be_false }
    it { subject.extra_valid?("http://test;ERR").should be_false }
    it { subject.extra_valid?("http://www.localhost:3000").should be_false }
    it { subject.extra_valid?("ftp://127.]boo[:3000").should be_false }
    it { subject.extra_valid?("www.joke;foo").should be_false }
    it { subject.extra_valid?("http://www.bob.com,,localhost:3000").should be_false }
  end

  describe "dev_valid?" do
    it { subject.dev_valid?(nil).should be_true }
    it { subject.dev_valid?("").should be_true }
    it { subject.dev_valid?("127.0.0.1").should be_true }
    it { subject.dev_valid?("10.0.0.0").should be_true }
    it { subject.dev_valid?("10.0.0.30").should be_true }
    it { subject.dev_valid?("10.255.255.255").should be_true }
    it { subject.dev_valid?("172.16.0.0").should be_true }
    it { subject.dev_valid?("172.16.0.30").should be_true }
    it { subject.dev_valid?("172.31.255.255").should be_true }
    it { subject.dev_valid?("192.168.0.0").should be_true }
    it { subject.dev_valid?("192.168.0.30").should be_true }
    it { subject.dev_valid?("192.168.255.255").should be_true }
    it { subject.dev_valid?("0.0.0.0").should be_true }
    it { subject.dev_valid?("google.local").should be_true }
    it { subject.dev_valid?("localhost").should be_true }
    it { subject.dev_valid?("localhost:8888").should be_true }
    it { subject.dev_valid?("google.prod").should be_true }
    # it { subject.dev_valid?("google.dev").should be_true } # THIS IS HUGELY SLOW DUE TO IPAddr.new('*.dev')!!!!!!!
    it { subject.dev_valid?("google.test").should be_true }
    it { subject.dev_valid?("http://www.localhost:3000").should be_true }
    it { subject.dev_valid?("www").should be_true }
    it { subject.dev_valid?("co.uk").should be_true }
    it { subject.dev_valid?("com").should be_true }

    it { subject.dev_valid?("éCOLE").should be_true }
    it { subject.dev_valid?("test;ERR").should be_true }
    it { subject.dev_valid?("http://test;ERR").should be_true }
    it { subject.dev_valid?("www.joke;foo").should be_true }
    it { subject.dev_valid?("ftp://127.]boo[:3000").should be_true }
    it { subject.dev_valid?("*.*").should be_true }
    it { subject.dev_valid?("*").should be_true }
    it { subject.dev_valid?(".com").should be_true }

    it { subject.dev_valid?("124.123.151.123").should be_false }
    it { subject.dev_valid?("11.0.0.0").should be_false }
    it { subject.dev_valid?("172.32.0.0").should be_false }
    it { subject.dev_valid?("192.169.0.0").should be_false }
    it { subject.dev_valid?("http://www.bob.com,,localhost:3000").should be_false }
    it { subject.dev_valid?("*.google.com").should be_false }
    it { subject.dev_valid?("staging.google.com").should be_false }
    it { subject.dev_valid?("test.google.com").should be_false }
    it { subject.dev_valid?("éCOLE.fr").should be_false }
    it { subject.dev_valid?("ASDASD.COM").should be_false }
    it { subject.dev_valid?("広告掲載.jp").should be_false }
    it { subject.dev_valid?("http://www.youtube.com?v=31231").should be_false }
    it { subject.dev_valid?("http://www.www.com").should be_false }
    it { subject.dev_valid?("www.com").should be_false }
    it { subject.dev_valid?("ftp://www.www.com").should be_false }
    it { subject.dev_valid?("https://www.co.uk").should be_false }
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
    it { subject.include?("http://localhost:3000, localhost", 'localhost').should be_true }
    it { subject.include?("124.123.151.123, localhost", '124.123.151.123').should be_true }
    it { subject.include?("127.0.0.1, bob, 127.0.0.1", 'bob').should be_true }
    it { subject.include?("*.*, *.*", '*.*').should be_true }
    it { subject.include?("google.fr, jilion.com", "google.fr").should be_true }

    it { subject.include?(nil, 'jilion.com').should be_false }
    it { subject.include?('jilion.com', nil).should be_false }
    it { subject.include?('jilion.com', "").should be_false }
    it { subject.include?(nil, nil).should be_false }
    it { subject.include?("", "").should be_false }
    it { subject.include?("", 'jilion.com').should be_false }
    it { subject.include?("localhost, jilion", 'jilion.com').should be_false }
  end

end
