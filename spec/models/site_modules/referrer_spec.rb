require 'spec_helper'

describe SiteModules::Referrer do

  describe "#referrer_type" do
    context "with versioning" do
      before(:all) do
        @site = with_versioning do
          Timecop.travel(1.day.ago) do
            @site2 = create(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "localhost, 127.0.0.1")
          end
          @site2.user.current_password = '123456'
          @site2.update_attributes(hostname: "jilion.net", extra_hostnames: 'jilion.org, jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1")
          @site2
        end
      end
      subject { @site }

      it { subject.referrer_type("http://jilion.net").should    eq "main" }
      it { subject.referrer_type("http://jilion.com").should    eq "extra" }
      it { subject.referrer_type("http://jilion.org").should    eq "extra" }
      it { subject.referrer_type("http://jilion.local").should  eq "dev" }
      it { subject.referrer_type("http://jilion.co.uk").should  eq "invalid" }

      it { subject.referrer_type("http://jilion.net", 1.day.ago + 1.hour).should    eq "extra" }
      it { subject.referrer_type("http://jilion.com", 1.day.ago + 1.hour).should    eq "main" }
      it { subject.referrer_type("http://jilion.org", 1.day.ago + 1.hour).should    eq "extra" }
      it { subject.referrer_type("http://jilion.local", 1.day.ago + 1.hour).should  eq "invalid" }
      it { subject.referrer_type("http://jilion.co.uk", 1.day.ago + 1.hour).should  eq "invalid" }
    end

    context "without wildcard or path" do
      before(:all) do
        @site = create(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, staging.jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1")
      end
      subject { @site }

      it { subject.referrer_type("http://Jilion.com").should           eq "main" }
      it { subject.referrer_type("http://jilion.com").should           eq "main" }
      it { subject.referrer_type("http://jilion.com/test/cool").should eq "main" }
      it { subject.referrer_type("https://jilion.com").should          eq "main" }
      it { subject.referrer_type("http://www.jilion.com").should       eq "main" }
      it { subject.referrer_type("http://jilion.com:80/demo").should   eq "main" }
      it { subject.referrer_type("https://jilion.com:443/demo").should eq "main" }

      it { subject.referrer_type("http://staging.jilion.com").should eq "extra" }
      it { subject.referrer_type("http://jilion.org").should         eq "extra" }

      it { subject.referrer_type("http://jilion.local").should              eq "dev" }
      it { subject.referrer_type("http://127.0.0.1:3000/super.html").should eq "dev" }
      it { subject.referrer_type("http://localhost:3000?genial=com").should eq "dev" }

      it { subject.referrer_type("http://blog.jilion.local").should eq "invalid" }
      it { subject.referrer_type("http://blog.jilion.com").should   eq "invalid" }
      it { subject.referrer_type("http://google.com").should        eq "invalid" }
      it { subject.referrer_type("google.com").should               eq "invalid" }
      it { subject.referrer_type("jilion.com").should               eq "invalid" }
      it { subject.referrer_type("junomsg://04E76D88/").should      eq "invalid" }
      it { subject.referrer_type("-").should                        eq "invalid" }
      it { subject.referrer_type(nil).should                        eq "invalid" }
    end

    context "with hostname with subdomain" do
      before(:all) do
        @site = create(:site, hostname: "blog.jilion.com", extra_hostnames: nil, dev_hostnames: nil)
      end
      subject { @site }

      it { subject.referrer_type("http://blog.jilion.com").should         eq "main" }
      it { subject.referrer_type("http://www.blog.jilion.com").should     eq "main" }
      it { subject.referrer_type("http://blog.jilion.com:80/demo").should eq "main" }
      it { subject.referrer_type("https://blog.jilion.com").should        eq "main" }

      it { subject.referrer_type("http://blog-jilion.com").should   eq "invalid" }
      it { subject.referrer_type("http://blog.jilion.local").should eq "invalid" }
      it { subject.referrer_type("http://google.com").should        eq "invalid" }
      it { subject.referrer_type("google.com").should               eq "invalid" }
      it { subject.referrer_type("jilion.com").should               eq "invalid" }
      it { subject.referrer_type("-").should                        eq "invalid" }
    end

    context "with wildcard" do
      before(:all) do
        @site = create(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "jilion.local, localhost, 127.0.0.1", wildcard: true)
      end
      subject { @site }

      it { subject.referrer_type("http://blog.jilion.com").should      eq "main" }
      it { subject.referrer_type("http://jilion.com").should           eq "main" }
      it { subject.referrer_type("http://jilion.com/test/cool").should eq "main" }
      it { subject.referrer_type("https://jilion.com").should          eq "main" }
      it { subject.referrer_type("http://www.jilion.com").should       eq "main" }
      it { subject.referrer_type("http://staging.jilion.com").should   eq "main" }
      it { subject.referrer_type("https://staging.jilion.com").should  eq "main" }
      it { subject.referrer_type("http://jilion.com:80/demo").should   eq "main" }
      it { subject.referrer_type("https://jilion.com:443/demo").should eq "main" }

      it { subject.referrer_type("http://jilion.org").should      eq "extra" }
      it { subject.referrer_type("http://jilion.net").should      eq "extra" }
      it { subject.referrer_type("http://jilion.net:80").should   eq "extra" }
      it { subject.referrer_type("https://jilion.net:443").should eq "extra" }

      it { subject.referrer_type("http://jilion.local").should              eq "dev" }
      it { subject.referrer_type("http://staging.jilion.local").should      eq "dev" }
      it { subject.referrer_type("http://127.0.0.1:3000/super.html").should eq "dev" }
      it { subject.referrer_type("http://localhost:3000?genial=com").should eq "dev" }

      # invalid top-domain
      it { subject.referrer_type("http://google.com").should      eq "invalid" }
      it { subject.referrer_type("http://superjilion.com").should eq "invalid" }
      it { subject.referrer_type("http://superjilion.org").should eq "invalid" }
      it { subject.referrer_type("http://superjilion.net").should eq "invalid" }
      it { subject.referrer_type("google.com").should             eq "invalid" }
      it { subject.referrer_type("jilion.com").should             eq "invalid" }
      it { subject.referrer_type("-").should                      eq "invalid" }
      it { subject.referrer_type(nil).should                      eq "invalid" }
    end

    context "with path" do
      before(:all) do
        @site = create(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, staging.jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1", path: "demo/boo")
      end
      subject { @site }

      it { subject.referrer_type("http://jilion.com/Demo/boo").should       eq "main" }
      it { subject.referrer_type("http://jilion.com/demo/boo").should       eq "main" }
      it { subject.referrer_type("http://jilion.com/demo/boo/cool").should  eq "main" }
      it { subject.referrer_type("https://jilion.com/demo/boo/").should     eq "main" }
      it { subject.referrer_type("http://jilion.com:80/demo/boo").should    eq "main" }
      it { subject.referrer_type("https://jilion.com:443/demo/boo").should  eq "main" }
      it { subject.referrer_type("http://jilion.com/demo/boo/cool").should  eq "main" }

      it { subject.referrer_type("http://jilion.org/demo/boo").should              eq "extra" }
      it { subject.referrer_type("http://jilion.org:80/demo/boo").should           eq "extra" }
      it { subject.referrer_type("http://jilion.org:80/demo/boo/").should          eq "extra" }
      it { subject.referrer_type("http://jilion.org/demo/boo/cool").should         eq "extra" }
      it { subject.referrer_type("http://staging.jilion.com/demo/boo/cool").should eq "extra" }

      it { subject.referrer_type("http://jilion.local").should                   eq "dev" }
      it { subject.referrer_type("http://127.0.0.1:3000/demo/super.html").should eq "dev" }
      it { subject.referrer_type("http://localhost:3000/demo?genial=com").should eq "dev" }
      it { subject.referrer_type("http://localhost:3000?genial=com").should      eq "dev" }

      # not registered subdomain, even with good path
      it { subject.referrer_type("http://cool.jilion.local").should      eq "invalid" }
      it { subject.referrer_type("http://cool.jilion.local/demo").should eq "invalid" }

      # wrong path
      it { subject.referrer_type("http://jilion.com/demoo").should     eq "invalid" }
      it { subject.referrer_type("http://jilion.com/demo/booo").should eq "invalid" }
      it { subject.referrer_type("http://jilion.com/test/cool").should eq "invalid" }
      it { subject.referrer_type("http://jilion.com:80/test").should   eq "invalid" }
      it { subject.referrer_type("https://jilion.com:443/test").should eq "invalid" }

      # right path, but not registered main or extra domain but containing main or extra domain in it
      it { subject.referrer_type("http://superjilion.com/demo/boo").should       eq "invalid" }
      it { subject.referrer_type("http://superjilion.org/demo/boo").should       eq "invalid" }
      it { subject.referrer_type("http://topstaging.jilion.com/demo/boo").should eq "invalid" }

      # not allowed without path
      it { subject.referrer_type("http://jilion.com").should      eq "invalid" }
      it { subject.referrer_type("http://jilion.org").should      eq "invalid" }
      it { subject.referrer_type("http://jilion.com:80").should   eq "invalid" }
      it { subject.referrer_type("https://jilion.com:443").should eq "invalid" }
      it { subject.referrer_type("https://jilion.com").should     eq "invalid" }
      it { subject.referrer_type("http://www.jilion.com").should  eq "invalid" }
      it { subject.referrer_type("http://blog.jilion.com").should eq "invalid" }
      it { subject.referrer_type("http://google.com").should      eq "invalid" }
      it { subject.referrer_type("google.com").should             eq "invalid" }
      it { subject.referrer_type("jilion.com").should             eq "invalid" }
      it { subject.referrer_type("-").should                      eq "invalid" }
      it { subject.referrer_type(nil).should                      eq "invalid" }
    end

    context "with wildcard and path" do
      before(:all) do
        @site = create(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "jilion.local, localhost, 127.0.0.1", path: "demo", wildcard: true)
      end
      subject { @site }

      it { subject.referrer_type("http://jilion.com/demo").should             eq "main" }
      it { subject.referrer_type("http://jilion.com/Demo").should             eq "main" }
      it { subject.referrer_type("https://jilion.com/demo").should            eq "main" }
      it { subject.referrer_type("https://jilion.com/demo/").should           eq "main" }
      it { subject.referrer_type("https://Jilion.com/demo").should            eq "main" }
      it { subject.referrer_type("http://staging.jilion.com/demo").should     eq "main" }
      it { subject.referrer_type("http://staging.jilion.com/demo/bob").should eq "main" }
      it { subject.referrer_type("http://staging.jilion.com:80/demo").should  eq "main" }
      it { subject.referrer_type("http://jilion.com/demo/cool").should        eq "main" }
      it { subject.referrer_type("http://jilion.com:80/demo").should          eq "main" }
      it { subject.referrer_type("https://jilion.com:443/demo").should        eq "main" }

      it { subject.referrer_type("http://jilion.org/demo").should      eq "extra" }
      it { subject.referrer_type("http://jilion.org:80/demo").should   eq "extra" }
      it { subject.referrer_type("http://jilion.net/demo/cool").should eq "extra" }

      it { subject.referrer_type("http://staging.jilion.local/demo/top").should  eq "dev" }
      it { subject.referrer_type("http://127.0.0.1:3000/demo/super.html").should eq "dev" }
      it { subject.referrer_type("http://localhost:3000/demo?genial=com").should eq "dev" }
      it { subject.referrer_type("http://jilion.local").should                   eq "dev" }
      it { subject.referrer_type("http://cool.jilion.local").should              eq "dev" }
      it { subject.referrer_type("http://jilion.local").should                   eq "dev" }
      it { subject.referrer_type("http://localhost:3000?genial=com").should      eq "dev" }

      # right path, but not registered main or extra domain but containing main or extra domain in it
      it { subject.referrer_type("http://superjilion.com/demo").should eq "invalid" }
      it { subject.referrer_type("http://superjilion.org/demo").should eq "invalid" }

      # not allowed without path
      it { subject.referrer_type("http://blog.jilion.com").should       eq "invalid" }
      it { subject.referrer_type("http://blog.jilion.com/demoo").should eq "invalid" }
      it { subject.referrer_type("http://jilion.com").should            eq "invalid" }
      it { subject.referrer_type("http://jilion.com/test/cool").should  eq "invalid" }
      it { subject.referrer_type("https://jilion.com").should           eq "invalid" }
      it { subject.referrer_type("http://jilion.com:80").should         eq "invalid" }
      it { subject.referrer_type("https://jilion.com:443").should       eq "invalid" }
      it { subject.referrer_type("http://www.jilion.com").should        eq "invalid" }
      it { subject.referrer_type("http://staging.jilion.com").should    eq "invalid" }
      it { subject.referrer_type("http://jilion.org").should            eq "invalid" }
      it { subject.referrer_type("http://jilion.net").should            eq "invalid" }
      it { subject.referrer_type("http://jilion.com").should            eq "invalid" }
      it { subject.referrer_type("https://jilion.com").should           eq "invalid" }
      it { subject.referrer_type("http://www.jilion.com").should        eq "invalid" }
      it { subject.referrer_type("http://blog.jilion.com").should       eq "invalid" }
      it { subject.referrer_type("http://google.com").should            eq "invalid" }
      it { subject.referrer_type("google.com").should                   eq "invalid" }
      it { subject.referrer_type("jilion.com").should                   eq "invalid" }
      it { subject.referrer_type("-").should                            eq "invalid" }
      it { subject.referrer_type(nil).should                            eq "invalid" }
    end

    context "custom" do
      before(:all) { @site = create(:site, hostname: "capped.tv", path: "lft-turbulence|mq") }
      before(:each) { Notify.should_not_receive(:send) }
      subject { @site }

      it { subject.referrer_type("-").should                                                     eq "invalid" }
      it { subject.referrer_type("123456789").should                                             eq "invalid" }
      it { subject.referrer_type("http://capped.tv/lft-turbulence|mq").should                    eq "main" }
      it { subject.referrer_type("http://www.optik-muncke.de/l%xc3%xb6sungen-sehen.html").should eq "invalid" }
      it { subject.referrer_type("http://www.joyce.com/40th/opening.swf/[[DYNAMIC]]/3").should   eq "invalid" }
      it { subject.referrer_type("http://panda_account.dev/").should                             eq "invalid" }
    end
  end

end
