require 'spec_helper'

describe Hostname do
  subject { Hostname }
  
  describe "clean" do
    it { subject.clean(nil).should == nil }
    it { subject.clean("").should == "" }
    it { subject.clean("éCOLE").should == "école" }
    it { subject.clean("éCOLE.fr").should == "école.fr" }
    it { subject.clean("http://www.école.fr").should == "école.fr" }
    it { subject.clean(".com").should == ".com" }
    it { subject.clean("co.uk").should == "co.uk" }
    it { subject.clean("*.com").should == "*.com" }
    it { subject.clean("www.*.com").should == "*.com" }
    it { subject.clean("*").should == "*" }
    it { subject.clean(".").should == "." }
    it { subject.clean("ASDASD.COM").should == "asdasd.com" }
    it { subject.clean("124.123.151.123").should == "124.123.151.123" }
    it { subject.clean("広告掲載.jp").should == "広告掲載.jp" }
    it { subject.clean("http://www.youtube.com?v=31231").should == "youtube.com" }
    it { subject.clean("web.me.com/super.fun").should == "web.me.com" }
    it { subject.clean("http://www.www.com").should == "www.com" }
    it { subject.clean("www.com").should == "www.com" }
    it { subject.clean("ftp://www.www.com").should == "www.com" }
    it { subject.clean("https://www.co.uk").should == "www.co.uk" }
    it { subject.clean("localhost").should == "localhost" }
    it { subject.clean("www").should == "www" }
    it { subject.clean("test;ERR").should == "test;err" }
    it { subject.clean("http://test;ERR").should == "test;err" }
    it { subject.clean("http://www.localhost:3000").should == "www.localhost" }
    it { subject.clean("ftp://127.]boo[:3000").should == "127.]boo[:3000" }
    it { subject.clean("www.joke;foo").should == "joke;foo" }
    it { subject.clean("http://www.bob.com,,localhost:3000").should == "bob.com, localhost" }
  end
  
  describe "valid?" do
    it { subject.valid?(nil).should be_false }
    it { subject.valid?("").should be_false }
    it { subject.valid?(".com").should be_false }
    it { subject.valid?("co.uk").should be_false }
    it { subject.valid?("www").should be_false }
    it { subject.valid?("*").should be_false }
    it { subject.valid?("*.*").should be_false }
    it { subject.valid?("*.google.com").should be_true }
    it { subject.valid?("éCOLE").should be_false }
    it { subject.valid?("éCOLE.fr").should be_true }
    it { subject.valid?("ASDASD.COM").should be_true }
    it { subject.valid?("124.123.151.123").should be_false }
    it { subject.valid?("広告掲載.jp").should be_true }
    it { subject.valid?("http://www.youtube.com?v=31231").should be_true }
    it { subject.valid?("http://www.www.com").should be_true }
    it { subject.valid?("www.com").should be_true }
    it { subject.valid?("ftp://www.www.com").should be_true }
    it { subject.valid?("https://www.co.uk").should be_true }
    it { subject.valid?("localhost").should be_false }
    it { subject.valid?("com").should be_false }
    it { subject.valid?("test;ERR").should be_false }
    it { subject.valid?("http://test;ERR").should be_false }
    it { subject.valid?("http://www.localhost:3000").should be_false }
    it { subject.valid?("ftp://127.]boo[:3000").should be_false }
    it { subject.valid?("www.joke;foo").should be_false }
    it { subject.valid?("http://www.bob.com,,localhost:3000").should be_false }
  end
  
  describe "wildcard?" do
    it { subject.wildcard?(nil).should be_false }
    it { subject.wildcard?("").should be_false }
    it { subject.wildcard?("co.uk").should be_false }
    it { subject.wildcard?("*.com").should be_true }
    it { subject.wildcard?("www.*.com").should be_true }
    it { subject.wildcard?("bob.*.com").should be_true }
    it { subject.wildcard?("*").should be_true }
    it { subject.wildcard?("*.*").should be_true }
    it { subject.wildcard?("*.google.com").should be_true }
    it { subject.wildcard?("localhost").should be_false }
    it { subject.wildcard?("google.fr").should be_false }
    it { subject.wildcard?("google.fr, *.google.com").should be_true }
  end
  
end
