require 'spec_helper'

describe StatRequestParser do

  describe ".stat_incs" do
    let(:user_agent) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/534.48.3 (KHTML, like Gecko) Version/5.1 Safari/534.48.3" }

    context "load event" do

      %w[m e].each do |hostname|
        describe "#{hostname} hostname with 1 video loaded" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', d: 'd', h: hostname, vu: ['abcd1234'], pm: ['h']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "pv.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 1 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 1 } }
              ]
            })
          }
        end

        describe "embed #{hostname} hostname with 1 video loaded" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234'], pm: ['h'], em: 1
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "pv.em" => 1 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.em" => 1 } }
              ]
            })
          }
        end

        describe "#{hostname} hostname with 1 video loaded (but not on page load)" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234'], pm: ['h'], po: 1
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 1 } }
              ]
            })
          }
        end

        describe "embed #{hostname} hostname with 1 video loaded (but not on page load)" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234'], pm: ['h'], em: 1, po: 1
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.em" => 1 } }
              ]
            })
          }
        end

        describe "#{hostname} hostname with empty video loaded" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: [''], pm: ['h']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "pv.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 1 } },
              videos: []
            })
          }
        end

        describe "#{hostname} hostname with 2 video loaded" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234', 'efgh5678'], pm: ['h','f']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "pv.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 1, "md.f.d" => 1 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 1 } },
                { st: 'site1234', u: 'efgh5678', inc: { "vl.#{hostname}" => 1, "bp.saf-osx" => 1, "md.f.d" => 1 } }
              ]
            })
          }
        end

        describe "#{hostname} hostname with 2 video loaded (same player mode)" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234', 'efgh5678'], pm: ['h','h']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "pv.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 2 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 1 } },
                { st: 'site1234', u: 'efgh5678', inc: { "vl.#{hostname}" => 1, "bp.saf-osx" => 1, "md.h.d" => 1 } }
              ]
            })
          }
        end

        describe "#{hostname} hostname without pm params" do
          specify { expect { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234', 'efgh5678']
            }, user_agent) }.should raise_error(StatRequestParser::BadParamsError)
          }
        end
      end

      %w[d i].each do |hostname|
        describe "#{hostname} hostname with 1 video loaded" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234'], pm: ['h']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "pv.#{hostname}" => 1 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.#{hostname}" => 1 } }
              ]
            })
          }
        end

        describe "embed #{hostname} hostname with 1 video loaded" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234'], pm: ['h'], em: 1
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { } }
              ]
            })
          }
        end

        describe "#{hostname} hostname with empty video loaded" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: [''], pm: ['h']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "pv.#{hostname}" => 1 } },
              videos: []
            })
          }
        end

        describe "#{hostname} hostname with 1 video loaded (but not on page load)" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234'], pm: ['h'], po: 1
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.#{hostname}" => 1 } }
              ]
            })
          }
        end

        describe "embed #{hostname} hostname with 1 video loaded (but not on page load)" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234'], pm: ['h'], em: 1, po: 1
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { } }
              ]
            })
          }
        end

        describe "#{hostname} hostname with 2 video loaded" do
          specify { subject.stat_incs({
              t: 'site1234', e: 'l', h: hostname, d: 'd', vu: ['abcd1234', 'efgh5678'], pm: ['h','f']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "pv.#{hostname}" => 1 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', inc: { "vl.#{hostname}" => 1 } },
                { st: 'site1234', u: 'efgh5678', inc: { "vl.#{hostname}" => 1 } }
              ]
            })
          }
        end
      end

    end

    context "view event" do

      %w[m e].each do |hostname|
        describe "#{hostname} hostname" do
          specify { subject.stat_incs({
              t: 'site1234', e: 's', h: hostname, d: 'd', vu: 'abcd1234', vn: 'My Video', vcs: ['source12', 'source34']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "vv.#{hostname}" => 1 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', n: 'My Video', inc: { "vv.#{hostname}" => 1, "vs.source12" => 1 } }
              ]
            })
          }
        end

        describe "embed #{hostname} hostname" do
          specify { subject.stat_incs({
              t: 'site1234', e: 's', h: hostname, d: 'd', vu: 'abcd1234', vn: 'My Video', vcs: ['source12', 'source34'], em: 1
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "vv.em" => 1 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', n: 'My Video', inc: { "vv.em" => 1 } }
              ]
            })
          }
        end
      end

      %w[d i].each do |hostname|
        describe "#{hostname} hostname" do
          specify { subject.stat_incs({
              t: 'site1234', e: 's', h: hostname, d: 'd', vu: 'abcd1234', vn: 'My Video', vcs: ['source12', 'source34']
            }, user_agent).should eql({
              site: { t: 'site1234', inc: { "vv.#{hostname}" => 1 } },
              videos: [
                { st: 'site1234', u: 'abcd1234', n: 'My Video', inc: { "vv.#{hostname}" => 1 } }
              ]
            })
          }
        end

        describe "embed #{hostname} hostname" do
          specify { subject.stat_incs({
              t: 'site1234', e: 's', h: hostname, d: 'd', vu: 'abcd1234', vn: 'My Video', vcs: ['source12', 'source34'], em: 1
            }, user_agent).should eql({
              site: { t: 'site1234', inc: {} },
              videos: [
                { st: 'site1234', u: 'abcd1234', n: 'My Video', inc: {} }
              ]
            })
          }
        end
      end
    end
  end


  describe ".browser_and_platform_key" do
    specify { subject.browser_and_platform_key("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; de-at) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1").should eql("saf-osx") }
    specify { subject.browser_and_platform_key("Mozilla/5.0 (X11; U; Linux amd64; rv:5.0) Gecko/20100101 Firefox/5.0 (Debian)").should eql("fir-lin") }
    specify { subject.browser_and_platform_key("Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0; .NET CLR 3.5.30729; .NET CLR 3.0.30729; .NET CLR 2.0.50727; Media Center PC 6.0)").should eql("iex-win") }
    specify { subject.browser_and_platform_key("Mozilla/5.0 (Windows NT 5.1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.815.0 Safari/535.1").should eql("chr-win") }
    specify { subject.browser_and_platform_key("Mozilla/5.0 (Linux; U; Android 2.3.4; fr-fr; HTC Desire Build/GRJ22) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1").should eql("and-and") }
    specify { subject.browser_and_platform_key("Mozilla/5.0 (BlackBerry; U; BlackBerry 9700; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/6.0.0.546 Mobile Safari/534.8+").should eql("rim-rim") }
    specify { subject.browser_and_platform_key("BlackBerry9700/5.0.0.862 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/120").should eql("rim-rim") }
    specify { subject.browser_and_platform_key("Opera/9.80 (X11; Linux x86_64; U; Ubuntu/10.10 (maverick); pl) Presto/2.7.62 Version/11.01").should eql("ope-lin") }
    specify { subject.browser_and_platform_key("Mozilla/5.0 (webOS/1.0; U; en-US) AppleWebKit/525.27.1 (KHTML, like Geko) Version/1.0 Safari/525.27.1 Pre/1.0").should eql("weo-weo") }
    specify { subject.browser_and_platform_key("Mozilla/4.0 (compatible; MSIE 7.0; Windows Phone OS 7.0; Trident/3.1; IEMobile/7.0) Asus;Galaxy6").should eql("iex-wip") }
    specify { subject.browser_and_platform_key("Lynx/2.8.7rel.2 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/1.0.0a").should eql("oth-otd") }
    specify { subject.browser_and_platform_key("Mozilla/5.0 (X11; U; Linux armv7l; ru-RU; rv:1.9.2.3pre) Gecko/20100723 Firefox/3.5 Maemo Browser 1.7.4.8 RX-51 N900").should eql("fir-lin") }
    specify { subject.browser_and_platform_key("Opera/9.80 (J2ME/MIDP; Opera Mini/9.80 (J2ME/23.377; U; en) Presto/2.5.25 Version/10.54").should eql("oth-otm") }
    specify { subject.browser_and_platform_key("Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543a Safari/419.3").should eql("saf-iph") }
    specify { subject.browser_and_platform_key("Mozilla/5.0(iPad; U; CPU OS 4_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8F191 Safari/6533.18.5").should eql("saf-ipa") }
    specify { subject.browser_and_platform_key("Mozilla/5.0(iPad; U; CPU iPhone OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B314 Safari/531.21.10").should eql("saf-ipa") }
    specify { subject.browser_and_platform_key("Mozila/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Geckto) Version/3.0 Mobile/3A101a Safari/419.3").should eql("saf-ipo") }
    specify { subject.browser_and_platform_key("HotJava/1.1.2 FCS").should eql("oth-otd") }
    specify { subject.browser_and_platform_key("").should eql("oth-otd") }
  end

end
