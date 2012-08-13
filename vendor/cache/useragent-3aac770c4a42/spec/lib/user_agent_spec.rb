require 'spec_helper'

describe UserAgent do

  describe ".initialize" do
    it "should require a product" do
      lambda { UserAgent.new(nil) }.should raise_error(ArgumentError, "expected a value for product")
    end

    it "should set version to nil if it's blank" do
      UserAgent.new("Mozilla", "").version.should be_nil
    end

    it "should split comment to any array if a string is passed in" do
      useragent = UserAgent.new("Mozilla", "5.0", "Macintosh; U; Intel Mac OS X 10_5_3; en-us")
      useragent.comment.should == ["Macintosh", "U", "Intel Mac OS X 10_5_3", "en-us"]
    end
  end

  describe "#to_str" do
    specify { UserAgent.new("Mozilla").to_str.should == "Mozilla" }
    specify { UserAgent.new("Mozilla", "5.0").to_str.should == "Mozilla/5.0" }
    specify do
      useragent = UserAgent.new("Mozilla", "5.0", ["Macintosh", "U", "Intel Mac OS X 10_5_3", "en-us"])
      useragent.to_str.should == "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us)"
    end
    specify do
      useragent = UserAgent.new("Mozilla", nil, ["Macintosh"])
      useragent.to_str.should == "Mozilla (Macintosh)"
    end
  end

  describe "#to_s" do
    specify { UserAgent.new("Mozilla").to_str.should == UserAgent.new("Mozilla").to_s }
  end

  describe "#eql?" do
    specify { UserAgent.new("Mozilla").should                           eql(UserAgent.new("Mozilla")) }
    specify { UserAgent.new("Mozilla").should_not                       eql(UserAgent.new("Opera")) }
    specify { UserAgent.new("Mozilla", "5.0").should                    eql(UserAgent.new("Mozilla", "5.0")) }
    specify { UserAgent.new("Mozilla", "5.0").should_not                eql(UserAgent.new("Mozilla", "4.0")) }
    specify { UserAgent.new("Mozilla", "5.0", ["Macintosh"]).should     eql(UserAgent.new("Mozilla", "5.0", ["Macintosh"])) }
    specify { UserAgent.new("Mozilla", "5.0", ["Macintosh"]).should_not eql(UserAgent.new("Mozilla", "5.0", ["Windows"])) }
    specify { UserAgent.new("Mozilla", "5.0", ["Macintosh"]).should_not eql(UserAgent.new("Mozilla", "4.0", ["Macintosh"])) }
  end

  describe "#equal?" do
    specify { UserAgent.new("Mozilla").should_not equal(UserAgent.new("Mozilla")) }
    specify do
      user_agent = UserAgent.new("Mozilla")
      user_agent.should equal(user_agent)
    end
  end

  describe "::MATCHER" do
    specify { UserAgent::MATCHER.should =~ "" }
    specify { UserAgent::MATCHER.should =~ "Mozilla" }
    specify { UserAgent::MATCHER.should =~ "Mozilla/5.0" }
    specify { UserAgent::MATCHER.should =~ "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us)" }
    specify { UserAgent::MATCHER.should =~ "Mozilla (Macintosh; U; Intel Mac OS X 10_5_3; en-us)" }
    specify { UserAgent::MATCHER.should =~ "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; .NET CLR 1.1.4322; .NET CLR 2.0.50727)" }
  end

  describe ".parse" do
    it "should not end in an endless loop when a user agent string is not matched entirely" do
      UserAgent.parse("Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0; SIMBAR={6DB474EC-4E6F-4B85-B44F-F6015109769D}; GTB6.6; User-agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; http://bsalsa.com) (Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 6.0)); User-agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; http://bsalsa.com) (Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)); SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.5.30729; .NET CLR 3.0.30729; .NET4.0C)").should be_a(Array)
    end

    it "should concatenate user agents when coerced to a string" do
      string = UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18")
      string.to_str.should == "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18"
    end

    it "should parse an empty string" do
      UserAgent.parse("").should be_empty
    end

    it "should parse a 'nil' string" do
      UserAgent.parse(nil).should be_empty
    end

    it "should 'repair' strings with un-closed pairs parenthesis" do
      UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us").to_s.should == UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us)").to_s
    end

    it "should parse a single product" do
      useragent = UserAgent.new("Mozilla")
      UserAgent.parse("Mozilla").application.should == useragent
    end

    it "should parse a single product with version" do
      useragent = UserAgent.new("Mozilla", "5.0")
      UserAgent.parse("Mozilla/5.0").application.should == useragent
    end

    it "should parse a single product and comment (no version)" do
      useragent = UserAgent.new("Mozilla", nil, ["Macintosh"])
      UserAgent.parse("Mozilla (Macintosh)").application.should == useragent
    end

    it "should parse a single product, version, and comment" do
      useragent = UserAgent.new("Mozilla", "5.0", ["Macintosh", "U", "Intel Mac OS X 10_5_3", "en-us"])
      UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us)").application.should == useragent
    end

    it "should parse a single product, version, and comment, with space-padded semicolons" do
      useragent = UserAgent.new("Mozilla", "5.0", ["Macintosh", "U", "Intel Mac OS X 10_5_3", "en-us"])
      UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3 ; en-us; )").application.should == useragent
    end
  end

end
