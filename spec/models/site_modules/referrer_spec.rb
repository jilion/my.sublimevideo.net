require 'spec_helper'

describe SiteModules::Referrer do
  describe "#referrer_type" do
    context "with versioning" do
      let(:site) {
        site = with_versioning do
          Timecop.travel(1.day.ago) do
            @site2 = create(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "localhost, 127.0.0.1")
          end
          @site2.user.current_password = '123456'
          @site2.update(hostname: "jilion.net", extra_hostnames: 'jilion.org, jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1")
          @site2
        end
        site
      }
      subject { site }

      it { subject.referrer_type("http://jilion.net").should == "main" }
      it { subject.referrer_type("http://jilion.com").should == "extra" }
      it { subject.referrer_type("http://jilion.org").should == "extra" }
      it { subject.referrer_type("http://jilion.local").should == "dev" }
      it { subject.referrer_type("http://jilion.co.uk").should == "invalid" }

      it { subject.referrer_type("http://jilion.net", 1.day.ago + 1.hour).should == "extra" }
      it { subject.referrer_type("http://jilion.com", 1.day.ago + 1.hour).should == "main" }
      it { subject.referrer_type("http://jilion.org", 1.day.ago + 1.hour).should == "extra" }
      it { subject.referrer_type("http://jilion.local", 1.day.ago + 1.hour).should == "invalid" }
      it { subject.referrer_type("http://jilion.co.uk", 1.day.ago + 1.hour).should == "invalid" }
    end

    context "without wildcard or path" do
      let(:site) { build(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, staging.jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1") }
      subject { site }

      it { subject.referrer_type("http://Jilion.com").should == "main" }
      it { subject.referrer_type("http://jilion.com").should == "main" }
      it { subject.referrer_type("http://jilion.com/test/cool").should == "main" }
      it { subject.referrer_type("https://jilion.com").should == "main" }
      it { subject.referrer_type("http://www.jilion.com").should == "main" }
      it { subject.referrer_type("http://jilion.com:80/demo").should == "main" }
      it { subject.referrer_type("https://jilion.com:443/demo").should == "main" }

      it { subject.referrer_type("http://staging.jilion.com").should == "extra" }
      it { subject.referrer_type("http://jilion.org").should == "extra" }

      it { subject.referrer_type("http://jilion.local").should == "dev" }
      it { subject.referrer_type("http://127.0.0.1:3000/super.html").should == "dev" }
      it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }

      it { subject.referrer_type("http://blog.jilion.local").should == "invalid" }
      it { subject.referrer_type("http://blog.jilion.com").should == "invalid" }
      it { subject.referrer_type("http://google.com").should == "invalid" }
      it { subject.referrer_type("google.com").should == "invalid" }
      it { subject.referrer_type("jilion.com").should == "invalid" }
      it { subject.referrer_type("junomsg://04E76D88/").should == "invalid" }
      it { subject.referrer_type("-").should == "invalid" }
      it { subject.referrer_type(nil).should == "invalid" }
    end

    context "with hostname with subdomain" do
      let(:site) { build(:site, hostname: "blog.jilion.com", extra_hostnames: nil, dev_hostnames: nil) }
      subject { site }

      it { subject.referrer_type("http://blog.jilion.com").should == "main" }
      it { subject.referrer_type("http://www.blog.jilion.com").should == "main" }
      it { subject.referrer_type("http://blog.jilion.com:80/demo").should == "main" }
      it { subject.referrer_type("https://blog.jilion.com").should == "main" }

      it { subject.referrer_type("http://blog-jilion.com").should == "invalid" }
      it { subject.referrer_type("http://blog.jilion.local").should == "invalid" }
      it { subject.referrer_type("http://google.com").should == "invalid" }
      it { subject.referrer_type("google.com").should == "invalid" }
      it { subject.referrer_type("jilion.com").should == "invalid" }
      it { subject.referrer_type("-").should == "invalid" }
    end

    context "with wildcard" do
      let(:site) { build(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "jilion.local, localhost, 127.0.0.1", wildcard: true) }
      subject { site }

      it { subject.referrer_type("http://blog.jilion.com").should == "main" }
      it { subject.referrer_type("http://jilion.com").should == "main" }
      it { subject.referrer_type("http://jilion.com/test/cool").should == "main" }
      it { subject.referrer_type("https://jilion.com").should == "main" }
      it { subject.referrer_type("http://www.jilion.com").should == "main" }
      it { subject.referrer_type("http://staging.jilion.com").should == "main" }
      it { subject.referrer_type("https://staging.jilion.com").should == "main" }
      it { subject.referrer_type("http://jilion.com:80/demo").should == "main" }
      it { subject.referrer_type("https://jilion.com:443/demo").should == "main" }

      it { subject.referrer_type("http://jilion.org").should == "extra" }
      it { subject.referrer_type("http://jilion.net").should == "extra" }
      it { subject.referrer_type("http://jilion.net:80").should == "extra" }
      it { subject.referrer_type("https://jilion.net:443").should == "extra" }

      it { subject.referrer_type("http://jilion.local").should == "dev" }
      it { subject.referrer_type("http://staging.jilion.local").should == "dev" }
      it { subject.referrer_type("http://127.0.0.1:3000/super.html").should == "dev" }
      it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }

      # invalid top-domain
      it { subject.referrer_type("http://google.com").should == "invalid" }
      it { subject.referrer_type("http://superjilion.com").should == "invalid" }
      it { subject.referrer_type("http://superjilion.org").should == "invalid" }
      it { subject.referrer_type("http://superjilion.net").should == "invalid" }
      it { subject.referrer_type("google.com").should == "invalid" }
      it { subject.referrer_type("jilion.com").should == "invalid" }
      it { subject.referrer_type("-").should == "invalid" }
      it { subject.referrer_type(nil).should == "invalid" }
    end

    context "with path" do
      let(:site) { build(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, staging.jilion.com', dev_hostnames: "jilion.local, localhost, 127.0.0.1", path: "demo/boo") }
      subject { site }

      it { subject.referrer_type("http://jilion.com/Demo/boo").should == "main" }
      it { subject.referrer_type("http://jilion.com/demo/boo").should == "main" }
      it { subject.referrer_type("http://jilion.com/demo/boo/cool").should == "main" }
      it { subject.referrer_type("https://jilion.com/demo/boo/").should == "main" }
      it { subject.referrer_type("http://jilion.com:80/demo/boo").should == "main" }
      it { subject.referrer_type("https://jilion.com:443/demo/boo").should == "main" }
      it { subject.referrer_type("http://jilion.com/demo/boo/cool").should == "main" }

      it { subject.referrer_type("http://jilion.org/demo/boo").should == "extra" }
      it { subject.referrer_type("http://jilion.org:80/demo/boo").should == "extra" }
      it { subject.referrer_type("http://jilion.org:80/demo/boo/").should == "extra" }
      it { subject.referrer_type("http://jilion.org/demo/boo/cool").should == "extra" }
      it { subject.referrer_type("http://staging.jilion.com/demo/boo/cool").should == "extra" }

      it { subject.referrer_type("http://jilion.local").should == "dev" }
      it { subject.referrer_type("http://127.0.0.1:3000/demo/super.html").should == "dev" }
      it { subject.referrer_type("http://localhost:3000/demo?genial=com").should == "dev" }
      it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }

      # not registered subdomain, even with good path
      it { subject.referrer_type("http://cool.jilion.local").should == "invalid" }
      it { subject.referrer_type("http://cool.jilion.local/demo").should == "invalid" }
      # wrong path
      it { subject.referrer_type("http://jilion.com/demoo").should == "invalid" }
      it { subject.referrer_type("http://jilion.com/demo/booo").should == "invalid" }
      it { subject.referrer_type("http://jilion.com/test/cool").should == "invalid" }
      it { subject.referrer_type("http://jilion.com:80/test").should == "invalid" }
      it { subject.referrer_type("https://jilion.com:443/test").should == "invalid" }
      # right path, but not registered main or extra domain but containing main or extra domain in it
      it { subject.referrer_type("http://superjilion.com/demo/boo").should == "invalid" }
      it { subject.referrer_type("http://superjilion.org/demo/boo").should == "invalid" }
      it { subject.referrer_type("http://topstaging.jilion.com/demo/boo").should == "invalid" }
      # not allowed without path
      it { subject.referrer_type("http://jilion.com").should == "invalid" }
      it { subject.referrer_type("http://jilion.org").should == "invalid" }
      it { subject.referrer_type("http://jilion.com:80").should == "invalid" }
      it { subject.referrer_type("https://jilion.com:443").should == "invalid" }
      it { subject.referrer_type("https://jilion.com").should == "invalid" }
      it { subject.referrer_type("http://www.jilion.com").should == "invalid" }
      it { subject.referrer_type("http://blog.jilion.com").should == "invalid" }
      it { subject.referrer_type("http://google.com").should == "invalid" }
      it { subject.referrer_type("google.com").should == "invalid" }
      it { subject.referrer_type("jilion.com").should == "invalid" }
      it { subject.referrer_type("-").should == "invalid" }
      it { subject.referrer_type(nil).should == "invalid" }
    end

    context "with wildcard and path" do
      let(:site) { build(:site, hostname: "jilion.com", extra_hostnames: 'jilion.org, jilion.net', dev_hostnames: "jilion.local, localhost, 127.0.0.1", path: "demo", wildcard: true) }
      subject { site }

      it { subject.referrer_type("http://jilion.com/demo").should == "main" }
      it { subject.referrer_type("http://jilion.com/Demo").should == "main" }
      it { subject.referrer_type("https://jilion.com/demo").should == "main" }
      it { subject.referrer_type("https://jilion.com/demo/").should == "main" }
      it { subject.referrer_type("https://Jilion.com/demo").should == "main" }
      it { subject.referrer_type("http://staging.jilion.com/demo").should == "main" }
      it { subject.referrer_type("http://staging.jilion.com/demo/bob").should == "main" }
      it { subject.referrer_type("http://staging.jilion.com:80/demo").should == "main" }
      it { subject.referrer_type("http://jilion.com/demo/cool").should == "main" }
      it { subject.referrer_type("http://jilion.com:80/demo").should == "main" }
      it { subject.referrer_type("https://jilion.com:443/demo").should == "main" }

      it { subject.referrer_type("http://jilion.org/demo").should == "extra" }
      it { subject.referrer_type("http://jilion.org:80/demo").should == "extra" }
      it { subject.referrer_type("http://jilion.net/demo/cool").should == "extra" }

      it { subject.referrer_type("http://staging.jilion.local/demo/top").should == "dev" }
      it { subject.referrer_type("http://127.0.0.1:3000/demo/super.html").should == "dev" }
      it { subject.referrer_type("http://localhost:3000/demo?genial=com").should == "dev" }
      it { subject.referrer_type("http://jilion.local").should == "dev" }
      it { subject.referrer_type("http://cool.jilion.local").should == "dev" }
      it { subject.referrer_type("http://jilion.local").should == "dev" }
      it { subject.referrer_type("http://localhost:3000?genial=com").should == "dev" }

      # right path, but not registered main or extra domain but containing main or extra domain in it
      it { subject.referrer_type("http://superjilion.com/demo").should == "invalid" }
      it { subject.referrer_type("http://superjilion.org/demo").should == "invalid" }
      # not allowed without path
      it { subject.referrer_type("http://blog.jilion.com").should == "invalid" }
      it { subject.referrer_type("http://blog.jilion.com/demoo").should == "invalid" }
      it { subject.referrer_type("http://jilion.com").should == "invalid" }
      it { subject.referrer_type("http://jilion.com/test/cool").should == "invalid" }
      it { subject.referrer_type("https://jilion.com").should == "invalid" }
      it { subject.referrer_type("http://jilion.com:80").should == "invalid" }
      it { subject.referrer_type("https://jilion.com:443").should == "invalid" }
      it { subject.referrer_type("http://www.jilion.com").should == "invalid" }
      it { subject.referrer_type("http://staging.jilion.com").should == "invalid" }
      it { subject.referrer_type("http://jilion.org").should == "invalid" }
      it { subject.referrer_type("http://jilion.net").should == "invalid" }
      it { subject.referrer_type("http://jilion.com").should == "invalid" }
      it { subject.referrer_type("https://jilion.com").should == "invalid" }
      it { subject.referrer_type("http://www.jilion.com").should == "invalid" }
      it { subject.referrer_type("http://blog.jilion.com").should == "invalid" }
      it { subject.referrer_type("http://google.com").should == "invalid" }
      it { subject.referrer_type("google.com").should == "invalid" }
      it { subject.referrer_type("jilion.com").should == "invalid" }
      it { subject.referrer_type("-").should == "invalid" }
      it { subject.referrer_type(nil).should == "invalid" }
    end

    context "custom" do
      let(:site) { build(:site, hostname: "capped.tv", path: "lft-turbulence|mq") }
      subject { site }

      it { subject.referrer_type("-").should == "invalid" }
      it { subject.referrer_type("123456789").should == "invalid" }
      it { subject.referrer_type("http://capped.tv/lft-turbulence|mq").should == "main" }
      it { subject.referrer_type("http://www.optik-muncke.de/l%xc3%xb6sungen-sehen.html").should == "invalid" }
      it { subject.referrer_type("http://www.joyce.com/40th/opening.swf/[[DYNAMIC]]/3").should == "invalid" }
      it { subject.referrer_type("http://panda_account.dev/").should == "invalid" }
    end
  end

end
