require 'spec_helper'

describe Service::Settings, :fog_mock, :addons do
  before { CDN.stub(:delay) { mock(purge: true) } }

  context "with populates addons" do
    describe "default settings of a new site" do
      let(:site) {
        site = build(:site, hostname: 'test.com')
        Service::Site.new(site).initial_save
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
            enabled: true,
            realtime: false
          },
          allowed_settings: {
            enabled: {
              values: [true]
            },
            realtime: {
              values: [false]
            }
          }
        },
      } )}

      its(:kits) { should eq({
        "default" => {
          skin: { id: "sa.sb.sc"},
          plugins: {
            "videoPlayer" => {
              plugins: {
                "badge" => {
                  settings: {
                    enabled: true,
                    position: "bottomRight"
                  },
                  allowed_settings: {
                    enabled: {
                      values: [true]
                    },
                    position: {
                      values: ["bottomLeft", "bottomRight"]
                    }
                  },
                  id: "sa.sh.sp"
                },
                "controls" => {
                  settings: {
                    controls: "autohide"
                  },
                  allowed_settings: {
                    controls: {
                      values: ["none", "autohide", "sticky"]
                    }
                  },
                  id: "sa.sh.sq"
                },
                "initial" => {
                  settings: {
                    overlay_enabled: true,
                    overlay_color: "#000"
                  },
                  allowed_settings: {
                    overlay_enabled: {
                      values: [true, false]
                    },
                    overlay_color: {
                      values: ["#000"]
                    }
                  },
                  id: "sa.sh.sv"
                }
              },
              settings: {
                fullwindow_forced: false,
                stop_on_end: false,
                fullmode_enabled: true,
                volume_enabled: true
              },
              allowed_settings: {
                fullwindow_forced: {
                  values: [true, false]
                },
                stop_on_end: {
                  values: [true, false]
                },
                fullmode_enabled: {
                  values: [true, false]
                },
                volume_enabled: {
                  values: [true, false]
                }
              },
              id: "sa.sh.si"
            },
            "lightbox" => {
              settings: {
                autoplay: true,
                overlay_color: "#000",
                overlay_opacity: 0.7,
                close_button: "autohide",
                close_button_position: "left"
              },
              allowed_settings: {
                autoplay: {
                  values: [true, false]
                },
                overlay_color: {
                  values: ["#000"]
                },
                overlay_opacity: {
                  range: [0, 1]
                },
                close_button: {
                  values: ["none", "autohide", "sticky"]
                },
                close_button_position: {
                  values: ["left", "right"]
                }
              },
              id: "sa.sl.sm"
            }
          }
        }
      } )}

      its(:default_kit) { should eq('default') }

      describe "file" do
        it "has good content" do
          File.open(subject.file) do |f|
            f.read.should eq "settings = {\n  license: { {\"ku\":[\"test.com\"],\"kv\":[\"127.0.0.1\",\"localhost\"],\"kz\":null,\"ia\":null,\"ib\":\"beta\"} },\n  app: { {\"kf\":{\"ko\":{\"tm\":true,\"tn\":false},\"kp\":{\"tm\":{\"ih\":[true]},\"tn\":{\"ih\":[false]}}}} },\n  kits: { {\"default\":{\"kb\":{\"kn\":\"sa.sb.sc\"},\"ka\":{\"ke\":{\"ka\":{\"ki\":{\"ko\":{\"tm\":true,\"to\":\"bottomRight\"},\"kp\":{\"tm\":{\"ih\":[true]},\"to\":{\"ih\":[\"bottomLeft\",\"bottomRight\"]}},\"kn\":\"sa.sh.sp\"},\"tq\":{\"ko\":{\"tq\":\"autohide\"},\"kp\":{\"tq\":{\"ih\":[\"none\",\"autohide\",\"sticky\"]}},\"kn\":\"sa.sh.sq\"},\"kh\":{\"ko\":{\"tr\":true,\"tg\":\"#000\"},\"kp\":{\"tr\":{\"ih\":[true,false]},\"tg\":{\"ih\":[\"#000\"]}},\"kn\":\"sa.sh.sv\"}},\"ko\":{\"tb\":false,\"tc\":false,\"td\":true,\"te\":true},\"kp\":{\"tb\":{\"ih\":[true,false]},\"tc\":{\"ih\":[true,false]},\"td\":{\"ih\":[true,false]},\"te\":{\"ih\":[true,false]}},\"kn\":\"sa.sh.si\"},\"kd\":{\"ko\":{\"tf\":true,\"tg\":\"#000\",\"th\":0.7,\"ti\":\"autohide\",\"tl\":\"left\"},\"kp\":{\"tf\":{\"ih\":[true,false]},\"tg\":{\"ih\":[\"#000\"]},\"th\":{\"ii\":[0,1]},\"ti\":{\"ih\":[\"none\",\"autohide\",\"sticky\"]},\"tl\":{\"ih\":[\"left\",\"right\"]}},\"kn\":\"sa.sl.sm\"}}}} },\n  defaultKit: 'default'\n}\n"
          end
        end
      end
    end
  end
end
