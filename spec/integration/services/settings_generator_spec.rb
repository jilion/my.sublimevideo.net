require 'spec_helper'

describe SettingsGenerator do
  context "with populates addons" do
    describe "default settings of a new site" do
      let(:site) {
        site = build(:site, hostname: 'test.com')
        SiteManager.new(site).create
        site
      }
      let(:settings) { described_class.new(site, 'settings') }
      subject { settings }

      its(:license) { should eq({
        hosts: ["test.com"],
        staging_hosts: [],
        dev_hosts: ["127.0.0.1", "localhost"],
        path: nil,
        wildcard: nil,
        stage: "beta"
      } )}

      its(:app_settings) { should == {
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
      } }

      describe 'settings.kits["1"][:plugins]' do
        it 'has 3 plugins' do
          settings.kits['1'][:plugins].should have(3).items
        end
      end

      describe 'settings.kits["1"][:plugins]["videoPlayer"]' do
        it 'has the right settings for ["videoPlayer"][:plugins]["logo"]' do
          settings.kits['1'][:plugins]['videoPlayer'][:plugins]['logo'].should == {
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
          }
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["initial"]' do
          settings.kits['1'][:plugins]['videoPlayer'][:plugins]['initial'].should == {
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
          }
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["embed"]' do
          settings.kits['1'][:plugins]['videoPlayer'][:plugins]['embed'].should == {
            settings: {
              enable: true,
              size: '640'
            },
            allowed_settings: {
              enable: {
                values: [true, false]
              },
              size: {}
            },
            id: 'sa.sh.ub'
          }
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["controls"]' do
          settings.kits['1'][:plugins]['videoPlayer'][:plugins]['controls'].should == {
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
            id: 'sa.sh.sq'
          }
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["controls"]' do
          settings.kits['1'][:plugins]['videoPlayer'][:settings].should == {
            volume_enable: true,
            fullmode_enable: true,
            fullmode_priority: 'screen',
            on_end: 'nothing'
          }
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["controls"]' do
          settings.kits['1'][:plugins]['videoPlayer'][:allowed_settings].should == {
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
          }
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["controls"]' do
          settings.kits['1'][:plugins]['videoPlayer'][:id].should eq 'sa.sh.si'
        end
      end

      describe 'settings.kits["1"][:plugins]["lightbox"]' do
        it 'has the right settings for ["lightbox"][:settings]' do
          settings.kits['1'][:plugins]['lightbox'][:settings].should == {
            on_open: 'play',
            overlay_color: "#000",
            overlay_opacity: 0.7,
            close_button_enable: true,
            close_button_visibility: "autohide",
            close_button_position: "left"
          }
        end

        it 'has the right settings for ["lightbox"][:allowed_settings]' do
          settings.kits['1'][:plugins]['lightbox'][:allowed_settings].should == {
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
          }
        end

        it 'has the right settings for ["lightbox"][:id]' do
          settings.kits['1'][:plugins]['lightbox'][:id].should == 'sa.sl.sm'
        end
      end

      describe 'settings.kits["1"][:plugins]["imageViewer"]' do
        it 'has the right settings for ["imageViewer"][:settings]' do
          settings.kits['1'][:plugins]['imageViewer'][:settings].should == {}
        end

        it 'has the right settings for ["imageViewer"][:allowed_settings]' do
          settings.kits['1'][:plugins]['imageViewer'][:allowed_settings].should == {}
        end

        it 'has the right settings for ["imageViewer"][:id]' do
          settings.kits['1'][:plugins]['imageViewer'][:id].should == 'sa.sn.so'
        end
      end

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
            "tw": {
            "ko": {
            "iv":true,"tx":"640"},
            "kp": {
            "iv": {
            "ih":[true,false]},
            "tx": {
            }},
            "kn":"sa.sh.ub"}},
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