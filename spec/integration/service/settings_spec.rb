require 'spec_helper'

describe Service::Settings do
  context "with populates addons" do
    describe "default settings of a new site" do
      let(:site) {
        site = build(:site, hostname: 'test.com')
        Service::Site.new(site).create
        site
      }
      subject { described_class.new(site, 'settings') }

      its(:license) { should eq({
        hosts: ["test.com"],
        staging_hosts: [],
        dev_hosts: ["127.0.0.1", "localhost"],
        path: nil,
        wildcard: nil,
        stage: "beta"
      } )}

      its(:app_settings) { should eq({
        "stats" => {
          settings: {
            enable: true,
            realtime: false
          },
          allowed_settings: {
            enable: {
              values: [true]
            },
            realtime: {
              values: [false]
            }
          }
        },
      } )}

      its(:kits) { should eq({
        "1" => {
          skin: { id: "sa.sb.sc"},
          plugins: {
            "videoPlayer" => {
              plugins: {
                "logo" => {
                  settings: {
                    enable: true,
                    type: 'sv',
                    visibility: 'autohide',
                    position: 'bottom-right',
                    image_url: '',
                    link_url: nil
                  },
                  allowed_settings: {
                    enable: {
                      values: [true]
                    },
                    type: {
                      values: ['sv']
                    },
                    visibility: {
                      values: ['autohide', 'visible']
                    },
                    position: {
                      values: ['bottom-right']
                    },
                    image_url: {},
                    link_url: {}
                  },
                  id: "sa.sh.sp"
                },
                "sharing" => {
                  settings: {
                    enable: false,
                    enable_twitter: true,
                    enable_facebook: true,
                    enable_link: true,
                    enable_embed: true,
                    order: "twitter link facebook embed",
                    default_url: nil,
                    twitter_url: nil,
                    facebook_url: nil,
                    link_url: nil,
                    embed_url: nil,
                    embed_width: nil,
                    embed_height: nil
                  },
                  allowed_settings: {
                    enable: {
                      values: [true, false]
                    },
                    enable_twitter: {
                      values: [true, false]
                    },
                    enable_facebook: {
                      values: [true, false]
                    },
                    enable_link: {
                      values: [true, false]
                    },
                    enable_embed: {
                      values: [true, false]
                    },
                    order: {},
                    default_url: {},
                    twitter_url: {},
                    facebook_url: {},
                    link_url: {},
                    embed_url: {},
                    embed_width: {},
                    embed_height: {}
                  },
                  id: "sa.sh.sz"
                },
                "initial" => {
                  settings: {
                    overlay_enable: true,
                    overlay_visibility: 'autofade',
                    overlay_color: '#000'
                  },
                  allowed_settings: {
                    overlay_enable: {
                      values: [true, false]
                    },
                    overlay_visibility: {
                      values: ['autofade', 'visible'],
                    },
                    overlay_color: {
                      values: ["#000"]
                    }
                  },
                  id: "sa.sh.sv"
                },
                "controls" => {
                  settings: {
                    enable: true,
                    visibility: 'autohide'
                  },
                  allowed_settings: {
                    enable: {
                      values: [true, false]
                    },
                    visibility: {
                      values: ['autohide', 'visible']
                    }
                  },
                  id: "sa.sh.sq"
                }
              },
              settings: {
                volume_enable: true,
                fullmode_enable: true,
                fullmode_priority: 'screen',
                on_end: 'nothing'
              },
              allowed_settings: {
                volume_enable: {
                  values: [true, false]
                },
                fullmode_enable: {
                  values: [true, false]
                },
                fullmode_priority: {
                  values: ['screen', 'window']
                },
                on_end: {
                  values: ['nothing', 'replay', 'stop']
                }
              },
              id: "sa.sh.si"
            },
            "lightbox" => {
              settings: {
                on_open: 'play',
                overlay_color: "#000",
                overlay_opacity: 0.7,
                close_button_enable: true,
                close_button_visibility: "autohide",
                close_button_position: "left"
              },
              allowed_settings: {
                close_button_enable: {
                  values: [true, false],
                },
                on_open: {
                  values: ['nothing', 'play']
                },
                overlay_color: {
                  values: ["#000"]
                },
                overlay_opacity: {
                  range: [0.1, 1]
                },
                close_button_visibility: {
                  values: ["autohide", "visible"]
                },
                close_button_position: {
                  values: ["left", "right"]
                }
              },
              id: "sa.sl.sm"
            },
            "imageViewer" => {
              settings: {},
              allowed_settings: {},
              id: "sa.sn.so"
            }
          }
        }
      } )}

      its(:default_kit) { should eq('1') }

      describe "file" do
        it "has good content" do
          expected = <<-CONTENT.gsub(/^ {10}/, '')
          sublime_.iu("ko",[],
            function() {
            var a;return a= {
            kr: {
            "ku":["test.com"],
            "kw":[],
            "kv":["127.0.0.1","localhost"],
            "kz":null,"ia":null,"ib":"beta"},
            sa: {
            "kf": {
            "ko": {
            "iv":true,"tn":false},
            "kp": {
            "iv": {
            "ih":[true]},
            "tn": {
            "ih":[false]}}}},
            ks: {
            "1": {
            "kb": {
            "kn":"sa.sb.sc"},
            "ka": {
            "ke": {
            "ka": {
            "ki": {
            "ko": {
            "iv":true,"type":"sv","visibility":"autohide","position":"bottom-right","ij":"","ik":null},
            "kp": {
            "iv": {
            "ih":[true]},
            "type": {
            "ih":["sv"]},
            "visibility": {
            "ih":["autohide","visible"]},
            "position": {
            "ih":["bottom-right"]},
            "ij": {
            },
            "ik": {
            }},
            "kn":"sa.sh.sp"},
            "kg": {
            "ko": {
            "iv":true,"visibility":"autohide"},
            "kp": {
            "iv": {
            "ih":[true,false]},
            "visibility": {
            "ih":["autohide","visible"]}},
            "kn":"sa.sh.sq"},
            "kh": {
            "ko": {
            "it":true,"tr":"autofade","tg":"#000"},
            "kp": {
            "it": {
            "ih":[true,false]},
            "tr": {
            "ih":["autofade","visible"]},
            "tg": {
            "ih":["#000"]}},
            "kn":"sa.sh.sv"},
            "km": {
            "ko": {
            "iv":false,"iw":true,"io":true,"ip":true,"iq":true,"ir":"twitter link facebook embed","is":null,"ts":null,"tt":null,"ik":null,"tu":null,"tv":null,"tz":null},
            "kp": {
            "iv": {
            "ih":[true,false]},
            "iw": {
            "ih":[true,false]},
            "io": {
            "ih":[true,false]},
            "ip": {
            "ih":[true,false]},
            "iq": {
            "ih":[true,false]},
            "ir": {
            },
            "is": {
            },
            "ts": {
            },
            "tt": {
            },
            "ik": {
            },
            "tu": {
            },
            "tv": {
            },
            "tz": {
            }},
            "kn":"sa.sh.sz"}},
            "ko": {
            "te":true,"td":true,"tb":"screen","tc":"nothing"},
            "kp": {
            "te": {
            "ih":[true,false]},
            "td": {
            "ih":[true,false]},
            "tb": {
            "ih":["screen","window"]},
            "tc": {
            "ih":["nothing","replay","stop"]}},
            "kn":"sa.sh.si"},
            "kd": {
            "ko": {
            "kj":"play","tg":"#000","th":0.7,"il":true,"ti":"autohide","tl":"left"},
            "kp": {
            "kj": {
            "ih":["nothing","play"]},
            "tg": {
            "ih":["#000"]},
            "th": {
            "ii":[0.1,1]},
            "il": {
            "ih":[true,false]},
            "ti": {
            "ih":["autohide","visible"]},
            "tl": {
            "ih":["left","right"]}},
            "kn":"sa.sl.sm"},
            "kc": {
            "ko": {
            },
            "kp": {
            },
            "kn":"sa.sn.so"}}}},
            kt:"1"},
            [a]})
          CONTENT
          File.open(subject.file) do |f|
            f.read.gsub(/\{/, " {\n  ").gsub(/(\},|\],)/, "\\1\n  ").should eq expected
          end
        end
      end
    end
  end
end
