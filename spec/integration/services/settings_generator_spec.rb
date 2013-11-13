require 'spec_helper'

describe SettingsGenerator, :addons do
  context "with populates addons" do
    describe "default settings of a new site" do
      let(:site) {
        site = build(:site, hostname: 'test.com')
        SiteManager.new(site).create
        site
      }
      let(:settings) { described_class.new(site, 'settings') }
      subject { settings }

      it 'has default license' do
        expect(settings.license).to eq({
          hosts: ["test.com"],
          staging_hosts: [],
          dev_hosts: ["127.0.0.1", "localhost"],
          path: nil,
          wildcard: nil,
          stage: "beta"
        })
      end

      it 'has default app_settings' do
        expect(settings.app_settings).to eq({
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
          }
        })
      end

      describe 'settings.kits["1"][:plugins]' do
        it 'has 3 plugins' do
          expect(settings.kits['1'][:plugins].size).to eq(3)
        end
      end

      describe 'settings.kits["1"][:plugins]["videoPlayer"]' do
        it 'has the right settings for ["videoPlayer"][:plugins]["logo"]' do
          expect(settings.kits['1'][:plugins]['videoPlayer'][:plugins]['logo']).to eq({
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
          })
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["initial"]' do
          expect(settings.kits['1'][:plugins]['videoPlayer'][:plugins]['initial']).to eq({
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
          })
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["embed"]' do
          expect(settings.kits['1'][:plugins]['videoPlayer'][:plugins]['embed']).to eq({
            settings: {
              enable: true,
              type: 'manual',
              size: '640'
            },
            allowed_settings: {
              enable: {
                values: [true, false]
              },
              type: {
                values: ['manual']
              },
              size: {}
            },
            id: 'sa.sh.ub'
          })
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["controls"]' do
          expect(settings.kits['1'][:plugins]['videoPlayer'][:plugins]['controls']).to eq({
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
          })
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["controls"]' do
          expect(settings.kits['1'][:plugins]['videoPlayer'][:settings]).to eq({
            volume_enable: true,
            fullmode_enable: true,
            fullmode_priority: 'screen',
            on_end: 'nothing'
          })
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["controls"]' do
          expect(settings.kits['1'][:plugins]['videoPlayer'][:allowed_settings]).to eq({
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
          })
        end

        it 'has the right settings for ["videoPlayer"][:plugins]["controls"]' do
          expect(settings.kits['1'][:plugins]['videoPlayer'][:id]).to eq 'sa.sh.si'
        end
      end

      describe 'settings.kits["1"][:plugins]["lightbox"]' do
        it 'has the right settings for ["lightbox"][:settings]' do
          expect(settings.kits['1'][:plugins]['lightbox'][:settings]).to eq({
            on_open: 'play',
            overlay_color: "#000",
            overlay_opacity: 0.7,
            close_button_enable: true,
            close_button_visibility: "autohide",
            close_button_position: "left"
          })
        end

        it 'has the right settings for ["lightbox"][:allowed_settings]' do
          expect(settings.kits['1'][:plugins]['lightbox'][:allowed_settings]).to eq({
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
          })
        end

        it 'has the right settings for ["lightbox"][:id]' do
          expect(settings.kits['1'][:plugins]['lightbox'][:id]).to eq 'sa.sl.sm'
        end
      end

      describe 'settings.kits["1"][:plugins]["imageViewer"]' do
        it 'has the right settings for ["imageViewer"][:settings]' do
          expect(settings.kits['1'][:plugins]['imageViewer'][:settings]).to eq({})
        end

        it 'has the right settings for ["imageViewer"][:allowed_settings]' do
          expect(settings.kits['1'][:plugins]['imageViewer'][:allowed_settings]).to eq({})
        end

        it 'has the right settings for ["imageViewer"][:id]' do
          expect(settings.kits['1'][:plugins]['imageViewer'][:id]).to eq 'sa.sn.so'
        end
      end

      describe '#default_kit' do
        it { expect(settings.default_kit).to eq('1') }
      end

      describe 'cdn_files' do
        describe 'new settings' do
          it 'has good content' do
            expected = <<-CONTENT.gsub(/^ {12}/, '')
            /*! SublimeVideo settings  | (c) 2013 Jilion SA | http://sublimevideo.net
            */(function() {
               sublime_.define("settings",[],
              function() {
              var e,t,i;return t= {
              },
              e= {
              },
              i= {
              license: {
              "hosts":["test.com"],
              "stagingHosts":[],
              "devHosts":["127.0.0.1","localhost"],
              "path":null,"wildcard":null,"stage":"beta"},
              app: {
              "stats": {
              "settings": {
              "enable":true,"realtime":false},
              "allowedSettings": {
              "enable": {
              "values":[true]},
              "realtime": {
              "values":[false]}}}},
              kits: {
              "1": {
              "skin": {
              "module":"sublime/sublime_skin"},
              "plugins": {
              "videoPlayer": {
              "plugins": {
              "logo": {
              "settings": {
              "enable":true,"type":"sv","visibility":"autohide","position":"bottom-right","imageUrl":"","linkUrl":null},
              "allowedSettings": {
              "enable": {
              "values":[true]},
              "type": {
              "values":["sv"]},
              "visibility": {
              "values":["autohide","visible"]},
              "position": {
              "values":["bottom-right"]},
              "imageUrl": {
              },
              "linkUrl": {
              }},
              "id":"sa.sh.sp","module":"sublime/video/plugins/logo/logo"},
              "controls": {
              "settings": {
              "enable":true,"visibility":"autohide"},
              "allowedSettings": {
              "enable": {
              "values":[true,false]},
              "visibility": {
              "values":["autohide","visible"]}},
              "id":"sa.sh.sq","module":"sublime/video/plugins/controls/controls"},
              "initial": {
              "settings": {
              "overlayEnable":true,"overlayVisibility":"autofade","overlayColor":"#000"},
              "allowedSettings": {
              "overlayEnable": {
              "values":[true,false]},
              "overlayVisibility": {
              "values":["autofade","visible"]},
              "overlayColor": {
              "values":["#000"]}},
              "id":"sa.sh.sv","module":"sublime/video/plugins/poster/start_controller"},
              "embed": {
              "settings": {
              "enable":true,"type":"manual","size":"640"},
              "allowedSettings": {
              "enable": {
              "values":[true,false]},
              "type": {
              "values":["manual"]},
              "size": {
              }},
              "id":"sa.sh.ub","module":"sublime/video/plugins/embed/embed"}},
              "settings": {
              "volumeEnable":true,"fullmodeEnable":true,"fullmodePriority":"screen","onEnd":"nothing"},
              "allowedSettings": {
              "volumeEnable": {
              "values":[true,false]},
              "fullmodeEnable": {
              "values":[true,false]},
              "fullmodePriority": {
              "values":["screen","window"]},
              "onEnd": {
              "values":["nothing","replay","stop"]}},
              "id":"sa.sh.si","module":"sublime/video/video_app_plugin"},
              "lightbox": {
              "settings": {
              "onOpen":"play","overlayColor":"#000","overlayOpacity":0.7,"closeButtonEnable":true,"closeButtonVisibility":"autohide","closeButtonPosition":"left"},
              "allowedSettings": {
              "onOpen": {
              "values":["nothing","play"]},
              "overlayColor": {
              "values":["#000"]},
              "overlayOpacity": {
              "range":[0.1,1]},
              "closeButtonEnable": {
              "values":[true,false]},
              "closeButtonVisibility": {
              "values":["autohide","visible"]},
              "closeButtonPosition": {
              "values":["left","right"]}},
              "id":"sa.sl.sm","module":"sublime/lightbox/lightbox_app_plugin"},
              "imageViewer": {
              "settings": {
              },
              "allowedSettings": {
              },
              "id":"sa.sn.so","module":"sublime/image/image_app_plugin"}}}},
              defaultKit:"1"},
              t.exports=i,t.exports||e});;sublime_.component('settings');})();
CONTENT
            File.open(subject.cdn_files[0].file) do |f|
              expect(f.read.gsub(/\{/, " {\n  ").gsub(/(\},|\],)/, "\\1\n  ")).to eq expected.strip
            end
          end
        end
      end

    end
  end
end
