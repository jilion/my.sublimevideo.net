require 'spec_helper'

describe Service::Settings, :fog_mock do
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
            "lightbox" => {
              settings: {
                enable_close_button: true,
                on_open: 'play',
                overlay_color: "#000",
                overlay_opacity: 0.7,
                close_button_visibility: "autohide",
                close_button_position: "left"
              },
              allowed_settings: {
                enable_close_button: {
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
            "videoPlayer" => {
              plugins: {
                "logo" => {
                  settings: {
                    enable: true,
                    type: 'sv',
                    visibility: 'autohide',
                    position: 'bottomRight',
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
                      values: ['bottomRight']
                    },
                    image_url: {},
                    link_url: {}
                  },
                  id: "sa.sh.sp"
                },
                "sharing" => {
                  settings: {
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
                    enable_overlay: true,
                    overlay_visibility: 'autofade',
                    overlay_color: '#000'
                  },
                  allowed_settings: {
                    enable_overlay: {
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
                enable_volume: true,
                enable_fullmode: true,
                force_fullwindow: false,
                on_end: 'nothing'
              },
              allowed_settings: {
                enable_volume: {
                  values: [true, false]
                },
                enable_fullmode: {
                  values: [true, false]
                },
                force_fullwindow: {
                  values: [true, false]
                },
                on_end: {
                  values: ['nothing', 'replay', 'stop']
                }
              },
              id: "sa.sh.si"
            }
          }
        }
      } )}

      its(:default_kit) { should eq('1') }

      describe "file" do
        it "has good content" do
          expected = <<-CONTENT.gsub(/^ {10}/, '')
          sublime_.jd("ko",[],
            function() {
            var a;return a= {
            kr: {
            "ku":["test.com"],
            "kv":["127.0.0.1","localhost"],
            "kz":null,"ia":null,"ib":"beta"},
            sa: {
            "kf": {
            "ko": {
            "if":true,"tn":false},
            "kp": {
            "if": {
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
            "if":true,"im":"sv","tq":"autohide","to":"bottomRight","ij":"","ik":null},
            "kp": {
            "if": {
            "ih":[true]},
            "im": {
            "ih":["sv"]},
            "tq": {
            "ih":["autohide","visible"]},
            "to": {
            "ih":["bottomRight"]},
            "ij": {
            },
            "ik": {
            }},
            "kn":"sa.sh.sp"},
            "kg": {
            "ko": {
            "if":true,"tq":"autohide"},
            "kp": {
            "if": {
            "ih":[true,false]},
            "tq": {
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
            "in":true,"io":true,"ip":true,"iq":true,"ir":"twitter link facebook embed","is":null,"ts":null,"tt":null,"ik":null,"tu":null,"tv":null,"tz":null},
            "kp": {
            "in": {
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
            "te":true,"td":true,"tb":false,"onEnd":"nothing"},
            "kp": {
            "te": {
            "ih":[true,false]},
            "td": {
            "ih":[true,false]},
            "tb": {
            "ih":[true,false]},
            "onEnd": {
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
            "kn":"sa.sl.sm"}}}},
            kt:'1'},
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
