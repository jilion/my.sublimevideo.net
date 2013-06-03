class AddonSystemPopulator < Populator

  def execute
    PopulateHelpers.empty_tables(App::Component, App::ComponentVersion, App::Plugin, AddonPlanSettings, Design, Addon, AddonPlan, BillableItem, BillableItemActivity)

    [App::Component, App::ComponentVersion, Design, Addon, App::Plugin, AddonPlan, AddonPlanSettings].each do |klass, new_records|
      seeds_method = klass.to_s.underscore.gsub('/', '_') + '_seeds'
      send(seeds_method).each do |attributes|
        attributes = attributes.call if attributes.respond_to?(:call)

        populator_class = "#{klass.to_s.demodulize}Populator"
        if Object.const_defined?(populator_class)
          populator = populator_class.constantize.new(attributes)
          populator.execute
        else
          klass.create(attributes, without_protection: true)
        end
      end
      puts "\t- #{klass.count} #{klass.to_s} created;" unless Rails.env.test?
    end
  end

  private

  def app_component_seeds
    [
      { name: 'app',      token: 'sa' },
      { name: 'twit',     token: 'sf' },
      { name: 'html5',    token: 'sg' },
      { name: 'sony',     token: 'tj' },
      { name: 'svnet',    token: 'sj' },
      { name: 'anthony',  token: 'aaa' },
      { name: 'next15',   token: 'aba' },
      { name: 'df',       token: 'afa' },
      { name: 'blizzard', token: 'aca' },

      { name: 'daily',  token: 'aha' },
      { name: 'psg',    token: 'aja' },
      { name: 'orange', token: 'aia' }
    ]
  end

  def app_component_version_seeds
    [
      { component: App::Component.get('app'),   version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
      { component: App::Component.get('twit'),  version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
      { component: App::Component.get('html5'), version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
      { component: App::Component.get('svnet'), version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) }
    ]
  end

  def design_seeds
    [
      { name: 'classic',  skin_token: 'sa.sb.sc',    price: 0, availability: 'public', stable_at: Time.now.utc, component: App::Component.get('app')      },
      { name: 'flat',     skin_token: 'sa.sd.sd',    price: 0, availability: 'public', stable_at: Time.now.utc, component: App::Component.get('app')      },
      { name: 'light',    skin_token: 'sa.se.se',    price: 0, availability: 'public', stable_at: Time.now.utc, component: App::Component.get('app')      },
      { name: 'twit',     skin_token: 'sf.sf.sf',    price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('twit')     },
      { name: 'html5',    skin_token: 'sg.sg.sg',    price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('html5')    },
      { name: 'sony',     skin_token: 'tj.tj.tj',    price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('sony')     },
      { name: 'svnet',    skin_token: 'sj.sj.sj',    price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('svnet')    },
      { name: 'anthony',  skin_token: 'aaa.aaa.aaa', price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('anthony')  },
      { name: 'next15',   skin_token: 'aba.aba.aba', price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('next15')   },
      { name: 'df',       skin_token: 'afa.afa.afa', price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('df')       },
      { name: 'blizzard', skin_token: 'aca.aca.aca', price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('blizzard') },

      { name: 'daily',  skin_token: 'aha.aha.aha', price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('daily') },
      { name: 'psg',    skin_token: 'aja.aja.aja', price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('psg') },
      { name: 'orange', skin_token: 'aia.aia.aia', price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('orange') }
    ]
  end

  def addon_seeds
    [
        -> { { name: 'video_player',     kind: 'videoPlayer',     design_dependent: false, parent_addon: nil } },
        -> { { name: 'controls',         kind: 'controls',        design_dependent: true,  parent_addon: Addon.get('video_player') } },
        -> { { name: 'initial',          kind: 'initial',         design_dependent: true,  parent_addon: Addon.get('video_player') } },
        -> { { name: 'sharing',          kind: 'sharing',         design_dependent: true,  parent_addon: Addon.get('video_player') } },
        -> { { name: 'social_sharing',   kind: 'sharing',         design_dependent: true,  parent_addon: Addon.get('video_player') } },
        -> { { name: 'embed',            kind: 'embed',           design_dependent: true,  parent_addon: Addon.get('video_player') } },
        -> { { name: 'image_viewer',     kind: 'imageViewer',     design_dependent: false, parent_addon: nil } },
        -> { { name: 'logo',             kind: 'logo',            design_dependent: false, parent_addon: Addon.get('video_player') } },
        -> { { name: 'lightbox',         kind: 'lightbox',        design_dependent: true,  parent_addon: nil } },
        -> { { name: 'api',              kind: 'api',             design_dependent: false, parent_addon: nil } },
        -> { { name: 'stats',            kind: 'stats',           design_dependent: false, parent_addon: nil } },
        -> { { name: 'support',          kind: 'support',         design_dependent: false, parent_addon: nil } },
        -> { { name: 'preview_tools',    kind: 'previewTools',    design_dependent: false, parent_addon: nil } },
        -> { { name: 'buy_action',       kind: 'buyAction',       design_dependent: true,  parent_addon: Addon.get('video_player') } },
        -> { { name: 'action',           kind: 'action',          design_dependent: false, parent_addon: Addon.get('video_player') } },
        -> { { name: 'end_actions',      kind: 'endActions',      design_dependent: true,  parent_addon: Addon.get('video_player') } },
        -> { { name: 'info',             kind: 'info',            design_dependent: true,  parent_addon: Addon.get('video_player') } },
        -> { { name: 'cuezones',         kind: 'cuezones',        design_dependent: false, parent_addon: Addon.get('video_player') } },
        -> { { name: 'google_analytics', kind: 'googleAnalytics', design_dependent: false, parent_addon: Addon.get('video_player') } },

        -> { { name: 'dmt_controls', kind: 'controls',    design_dependent: true, parent_addon: Addon.get('video_player') } },
        -> { { name: 'dmt_quality',  kind: 'qualityPane', design_dependent: true, parent_addon: Addon.get('video_player') } },
        -> { { name: 'dmt_logo',     kind: 'logo',        design_dependent: true, parent_addon: Addon.get('video_player') } },
        -> { { name: 'dmt_sharing',  kind: 'sharing',     design_dependent: true, parent_addon: Addon.get('video_player') } },

        -> { { name: 'psg_controls', kind: 'controls', design_dependent: true, parent_addon: Addon.get('video_player') } },
        -> { { name: 'psg_logo',     kind: 'logo',     design_dependent: true, parent_addon: Addon.get('video_player') } },

        -> { { name: 'rng_controls', kind: 'controls', design_dependent: true, parent_addon: Addon.get('video_player') } }
    ]
  end

  def addon_plan_seeds
    [
      { name: 'standard',  price: 0,    addon: Addon.get('video_player'),     availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('lightbox'),         availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('image_viewer'),     availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('preview_tools'),    availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('end_actions'),      availability: 'custom', stable_at: Time.now.utc },
      { name: 'invisible', price: 0,    addon: Addon.get('stats'),            availability: 'hidden', stable_at: Time.now.utc },
      { name: 'realtime',  price: 990,  addon: Addon.get('stats'),            availability: 'public', stable_at: Time.now.utc },
      { name: 'sublime',   price: 0,    addon: Addon.get('logo'),             availability: 'public', stable_at: Time.now.utc },
      { name: 'disabled',  price: 990,  addon: Addon.get('logo'),             availability: 'public', stable_at: Time.now.utc },
      { name: 'custom',    price: 1990, addon: Addon.get('logo'),             availability: 'public', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('controls'),         availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('initial'),          availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('sharing'),          availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 690,  addon: Addon.get('social_sharing'),   availability: 'public', stable_at: Time.now.utc },
      { name: 'manual',    price: 0,    addon: Addon.get('embed'),            availability: 'public', stable_at: Time.now.utc },
      { name: 'auto',      price: 990,  addon: Addon.get('embed'),            availability: 'public', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('api'),              availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('support'),          availability: 'public', stable_at: Time.now.utc },
      { name: 'vip',       price: 9990, addon: Addon.get('support'),          availability: 'public', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('buy_action'),       availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('info'),             availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('action'),           availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 690,  addon: Addon.get('cuezones'),         availability: 'public', stable_at: Time.now.utc },
      { name: 'standard',  price: 690,  addon: Addon.get('google_analytics'), availability: 'public', stable_at: Time.now.utc },

      { name: 'standard', price: 0, addon: Addon.get('dmt_controls'), availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard', price: 0, addon: Addon.get('dmt_quality'),  availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard', price: 0, addon: Addon.get('dmt_logo'),     availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard', price: 0, addon: Addon.get('dmt_sharing'),  availability: 'custom', stable_at: Time.now.utc },

      { name: 'standard', price: 0, addon: Addon.get('psg_controls'), availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard', price: 0, addon: Addon.get('psg_logo'),     availability: 'custom', stable_at: Time.now.utc },

      { name: 'standard', price: 0, addon: Addon.get('rng_controls'),  availability: 'custom', stable_at: Time.now.utc }
    ]
  end

  def app_plugin_seeds
    [
      { name: 'video_player',           mod:'sublime/video/video_app_plugin', token: 'sa.sh.si',    addon: Addon.get('video_player'),     design: nil,                         component: App::Component.get('app') },

      { name: 'lightbox_classic',       mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('classic'),  component: App::Component.get('app') },
      { name: 'lightbox_flat',          mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('flat'),     component: App::Component.get('app') },
      { name: 'lightbox_light',         mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('light'),    component: App::Component.get('app') },
      { name: 'lightbox_twit',          mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('twit'),     component: App::Component.get('app') },
      { name: 'lightbox_html5',         mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('html5'),    component: App::Component.get('app') },
      { name: 'lightbox_sony',          mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('sony'),     component: App::Component.get('app') },
      { name: 'lightbox_anthony',       mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('anthony'),  component: App::Component.get('app') },
      { name: 'lightbox_next15',        mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('next15'),   component: App::Component.get('app') },
      { name: 'lightbox_df',            mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('df'),       component: App::Component.get('app') },
      { name: 'lightbox_blizzard',      mod:'sublime/lightbox/lightbox_app_plugin', token: 'sa.sl.sm',    addon: Addon.get('lightbox'),         design: Design.get('blizzard'), component: App::Component.get('app') },

      { name: 'image_viewer',           mod:'sublime/image/image_app_plugin', token: 'sa.sn.so',    addon: Addon.get('image_viewer'),     design: nil,                         component: App::Component.get('app') },

      { name: 'logo',                   mod:'sublime/video/plugins/logo/logo', token: 'sa.sh.sp',    addon: Addon.get('logo'),             design: nil,                         component: App::Component.get('app') },

      { name: 'controls_classic',       mod:'sublime/video/plugins/controls/controls',    token: 'sa.sh.sq',    addon: Addon.get('controls'),         design: Design.get('classic'),  component: App::Component.get('app') },
      { name: 'controls_flat',          mod:'players/flat/plugins/controls/controls',     token: 'sd.sd.sr',    addon: Addon.get('controls'),         design: Design.get('flat'),     component: App::Component.get('app') },
      { name: 'controls_light',         mod:'players/light/plugins/controls/controls',    token: 'se.se.ss',    addon: Addon.get('controls'),         design: Design.get('light'),    component: App::Component.get('app') },
      { name: 'controls_twit',          mod:'players/twit/plugins/controls/controls',     token: 'sf.sf.st',    addon: Addon.get('controls'),         design: Design.get('twit'),     component: App::Component.get('twit') },
      { name: 'controls_html5',         mod:'players/html5/plugins/controls/controls',    token: 'sg.sg.su',    addon: Addon.get('controls'),         design: Design.get('html5'),    component: App::Component.get('html5') },
      { name: 'controls_sony',          mod:'players/sony/plugins/controls/controls',     token: 'tj.tj.sx',    addon: Addon.get('controls'),         design: Design.get('sony'),     component: App::Component.get('sony') },
      { name: 'controls_anthony',       mod:'players/anthony/plugins/controls/controls',  token: 'aaa.aaa.aab', addon: Addon.get('controls'),         design: Design.get('anthony'),  component: App::Component.get('anthony') },
      { name: 'controls_next15',        mod:'players/next15/plugins/controls/controls',   token: 'aba.aba.abb', addon: Addon.get('controls'),         design: Design.get('next15'),   component: App::Component.get('next15') },
      { name: 'controls_df',            mod:'players/df/plugins/controls/controls',       token: 'afa.afa.afb', addon: Addon.get('controls'),         design: Design.get('df'),       component: App::Component.get('df') },
      { name: 'controls_blizzard',      mod:'players/blizzard/plugins/controls/controls', token: 'aca.aca.acd', addon: Addon.get('controls'),         design: Design.get('blizzard'), component: App::Component.get('blizzard') },

      { name: 'initial_classic',        mod:'sublime/video/plugins/poster/start_controller',     token: 'sa.sh.sv',    addon: Addon.get('initial'),          design: Design.get('classic'),  component: App::Component.get('app') },
      { name: 'initial_flat',           mod:'sublime/video/plugins/poster/start_controller',     token: 'sa.sh.sv',    addon: Addon.get('initial'),          design: Design.get('flat'),     component: App::Component.get('app') },
      { name: 'initial_light',          mod:'sublime/video/plugins/poster/start_controller',     token: 'sa.sh.sv',    addon: Addon.get('initial'),          design: Design.get('light'),    component: App::Component.get('app') },
      { name: 'initial_twit',           mod:'sublime/video/plugins/poster/start_controller',     token: 'sa.sh.sv',    addon: Addon.get('initial'),          design: Design.get('twit'),     component: App::Component.get('app') },
      { name: 'initial_html5',          mod:'sublime/video/plugins/poster/start_controller',     token: 'sa.sh.sv',    addon: Addon.get('initial'),          design: Design.get('html5'),    component: App::Component.get('app') },
      { name: 'initial_sony',           mod:'players/sony/plugins/poster/start_controller',      token: 'tj.tj.sy',    addon: Addon.get('initial'),          design: Design.get('sony'),     component: App::Component.get('sony') },
      { name: 'initial_anthony',        mod:'sublime/video/plugins/poster/start_controller',     token: 'sa.sh.sv',    addon: Addon.get('initial'),          design: Design.get('anthony'),  component: App::Component.get('app') },
      { name: 'initial_next15',         mod:'sublime/video/plugins/poster/start_controller',     token: 'sa.sh.sv',    addon: Addon.get('initial'),          design: Design.get('next15'),   component: App::Component.get('app') },
      { name: 'initial_df',             mod:'sublime/video/plugins/poster/start_controller',     token: 'sa.sh.sv',    addon: Addon.get('initial'),          design: Design.get('df'),       component: App::Component.get('app') },
      { name: 'initial_blizzard',       mod:'players/blizzard/plugins/poster/start_controller',  token: 'aca.aca.acc', addon: Addon.get('initial'),          design: Design.get('blizzard'), component: App::Component.get('blizzard') },

      { name: 'sharing_classic',        mod:'sublime/video/plugins/sharing/sharing_buttons' , token: 'sa.sh.sz',    addon: Addon.get('sharing'),          design: Design.get('classic'),  component: App::Component.get('app') },
      { name: 'sharing_twit',           mod:'sublime/video/plugins/sharing/sharing_buttons' , token: 'sa.sh.sz',    addon: Addon.get('sharing'),          design: Design.get('twit'),     component: App::Component.get('app') },
      { name: 'sharing_html5',          mod:'sublime/video/plugins/sharing/sharing_buttons' , token: 'sa.sh.sz',    addon: Addon.get('sharing'),          design: Design.get('html5'),    component: App::Component.get('app') },
      { name: 'sharing_next15',         mod:'players/next15/plugins/sharing/sharing_buttons', token: 'aba.aba.abc', addon: Addon.get('sharing'),          design: Design.get('next15'),   component: App::Component.get('next15') },
      { name: 'sharing_blizzard',       mod:'sublime/video/plugins/sharing/sharing_buttons' , token: 'sa.sh.sz',    addon: Addon.get('sharing'),          design: Design.get('blizzard'), component: App::Component.get('app') },
      { name: 'sharing_sony',           mod:'sublime/video/plugins/sharing/sharing_buttons' , token: 'sa.sh.sz',    addon: Addon.get('sharing'),          design: Design.get('sony'),     component: App::Component.get('app') },
      { name: 'sharing_psg',            mod:'sublime/video/plugins/sharing/sharing_buttons' , token: 'sa.sh.sz',    addon: Addon.get('sharing'),          design: Design.get('psg'),      component: App::Component.get('app') },
      { name: 'sharing_orange',         mod:'sublime/video/plugins/sharing/sharing_buttons' , token: 'sa.sh.sz',    addon: Addon.get('sharing'),          design: Design.get('orange'),   component: App::Component.get('app') },

      { name: 'social_sharing_classic', mod:'sublime/video/plugins/social_sharing/social_sharing', token: 'sa.sh.ua',    addon: Addon.get('social_sharing'),   design: Design.get('classic'),  component: App::Component.get('app') },
      { name: 'social_sharing_flat',    mod:'sublime/video/plugins/social_sharing/social_sharing', token: 'sa.sh.ua',    addon: Addon.get('social_sharing'),   design: Design.get('flat'),     component: App::Component.get('app') },
      { name: 'social_sharing_light',   mod:'sublime/video/plugins/social_sharing/social_sharing', token: 'sa.sh.ua',    addon: Addon.get('social_sharing'),   design: Design.get('light'),    component: App::Component.get('app') },

      { name: 'embed_classic',          mod:'sublime/video/plugins/embed/embed', token: 'sa.sh.ub',    addon: Addon.get('embed'),            design: Design.get('classic'),  component: App::Component.get('app') },
      { name: 'embed_flat',             mod:'sublime/video/plugins/embed/embed', token: 'sa.sh.ub',    addon: Addon.get('embed'),            design: Design.get('flat'),     component: App::Component.get('app') },
      { name: 'embed_light',            mod:'sublime/video/plugins/embed/embed', token: 'sa.sh.ub',    addon: Addon.get('embed'),            design: Design.get('light'),    component: App::Component.get('app') },

      { name: 'info_sony',              mod:'players/sony/plugins/info/info_controller', token: 'tj.tj.aeb',   addon: Addon.get('info'),             design: Design.get('sony'),     component: App::Component.get('sony') },

      { name: 'buy_action_blizzard',    mod:'players/blizzard/plugins/buy/buy_controller', token: 'aca.aca.acb', addon: Addon.get('buy_action'),       design: Design.get('blizzard'), component: App::Component.get('blizzard') },
      { name: 'buy_action_psg',         mod:'players/psg/plugins/buy/buy_controller',      token: 'aja.aja.ajd', addon: Addon.get('buy_action'),       design: Design.get('psg'),      component: App::Component.get('psg') },

      { name: 'preview_tools_svnet',    mod:'players/svnet/plugins/extended_video_app/extended_video_app_plugin', token: 'sj.sj.sk',    addon: Addon.get('preview_tools'),    design: nil,                         component: App::Component.get('svnet') },

      { name: 'end_actions_twit',       mod:'players/twit/plugins/actions/action_buttons', token: 'sf.sf.agb',   addon: Addon.get('end_actions'),      design: Design.get('twit'),     component: App::Component.get('twit') },

      { name: 'action_svnet',           mod:'players/svnet/plugins/actions/action_buttons', token: 'sj.sj.adb',   addon: Addon.get('action'),           design: nil,                         component: App::Component.get('svnet') },

      { name: 'cuezones',               mod:'sublime/video/plugins/cuepoints/cue_zones', token: 'sa.sh.ud',    addon: Addon.get('cuezones'),         design: nil,                         component: App::Component.get('app') },

      { name: 'google_analytics',       mod:'sublime/video/plugins/google_analytics/google_analytics', token: 'sa.sh.uf',    addon: Addon.get('google_analytics'), design: nil,                         component: App::Component.get('app') },

      { name: 'dmt_controls', mod:'players/daily/plugins/controls/controls'      , token: 'aha.aha.ahb', addon: Addon.get('dmt_controls'), design: Design.get('daily'), component: App::Component.get('daily') },
      { name: 'dmt_quality',  mod:'players/daily/plugins/quality/quality'        , token: 'aha.aha.ahc', addon: Addon.get('dmt_quality'),  design: Design.get('daily'), component: App::Component.get('daily') },
      { name: 'dmt_logo',     mod:'players/daily/plugins/logo/logo'              , token: 'aha.aha.ahd', addon: Addon.get('dmt_logo'),     design: Design.get('daily'), component: App::Component.get('daily') },
      { name: 'dmt_sharing',  mod:'players/daily/plugins/sharing/sharing_buttons', token: 'aha.aha.ahe', addon: Addon.get('dmt_sharing'),  design: Design.get('daily'), component: App::Component.get('daily') },

      { name: 'psg_controls', mod:'players/psg/plugins/controls/controls', token: 'aja.aja.ajb', addon: Addon.get('psg_controls'), design: Design.get('psg'), component: App::Component.get('psg') },
      { name: 'psg_logo',     mod:'players/psg/plugins/logo/logo',         token: 'aja.aja.ajc', addon: Addon.get('psg_logo'),     design: Design.get('psg'), component: App::Component.get('psg') },

      { name: 'rng_controls', mod:'players/orange/plugins/controls/controls', token: 'aia.aia.aib', addon: Addon.get('rng_controls'), design: Design.get('orange'), component: App::Component.get('orange') }
    ]
  end

  def addon_plan_settings_seeds
    [
      { addon_plan: AddonPlan.get('video_player', 'standard'),     plugin: App::Plugin.get('video_player')          },

      { addon_plan: AddonPlan.get('action', 'standard'),           plugin: App::Plugin.get('action_svnet')          },

      { addon_plan: AddonPlan.get('info', 'standard'),             plugin: App::Plugin.get('info_sony')             },

      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_classic')      },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_flat')         },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_light')        },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_twit')         },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_html5')        },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_sony')         },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_anthony')      },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_next15')       },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_df')           },
      { addon_plan: AddonPlan.get('controls', 'standard'),         plugin: App::Plugin.get('controls_blizzard')     },

      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_classic')      },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_flat'), suffix: 'without_close_button' },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_light'), suffix: 'without_close_button' },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_twit')         },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_html5')        },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_sony')         },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_anthony'), suffix: 'without_close_button' },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_next15')       },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_df')           },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),         plugin: App::Plugin.get('lightbox_blizzard'), suffix: 'without_close_button' },

      { addon_plan: AddonPlan.get('image_viewer', 'standard'),     plugin: App::Plugin.get('image_viewer')          },

      { addon_plan: AddonPlan.get('stats', 'invisible'),           plugin: nil                                      },
      { addon_plan: AddonPlan.get('stats', 'realtime'),            plugin: nil                                      },

      { addon_plan: AddonPlan.get('logo', 'sublime'),              plugin: App::Plugin.get('logo')                  },
      { addon_plan: AddonPlan.get('logo', 'disabled'),             plugin: App::Plugin.get('logo')                  },
      { addon_plan: AddonPlan.get('logo', 'custom'),               plugin: App::Plugin.get('logo')                  },

      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_classic')       },
      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_flat')          },
      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_light')         },
      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_twit')          },
      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_html5')         },
      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_sony')          },
      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_anthony')       },
      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_next15')        },
      { addon_plan: AddonPlan.get('initial', 'standard'),          plugin: App::Plugin.get('initial_blizzard')      },

      { addon_plan: AddonPlan.get('sharing', 'standard'),          plugin: App::Plugin.get('sharing_classic')       },
      { addon_plan: AddonPlan.get('sharing', 'standard'),          plugin: App::Plugin.get('sharing_twit')          },
      { addon_plan: AddonPlan.get('sharing', 'standard'),          plugin: App::Plugin.get('sharing_html5')         },
      { addon_plan: AddonPlan.get('sharing', 'standard'),          plugin: App::Plugin.get('sharing_next15')        },
      { addon_plan: AddonPlan.get('sharing', 'standard'),          plugin: App::Plugin.get('sharing_blizzard')      },
      { addon_plan: AddonPlan.get('sharing', 'standard'),          plugin: App::Plugin.get('sharing_sony')          },
      { addon_plan: AddonPlan.get('sharing', 'standard'),          plugin: App::Plugin.get('sharing_psg')           },
      { addon_plan: AddonPlan.get('sharing', 'standard'),          plugin: App::Plugin.get('sharing_orange')        },

      { addon_plan: AddonPlan.get('social_sharing', 'standard'),   plugin: App::Plugin.get('social_sharing_classic') },
      { addon_plan: AddonPlan.get('social_sharing', 'standard'),   plugin: App::Plugin.get('social_sharing_flat')   },
      { addon_plan: AddonPlan.get('social_sharing', 'standard'),   plugin: App::Plugin.get('social_sharing_light')  },

      { addon_plan: AddonPlan.get('embed', 'manual'),              plugin: App::Plugin.get('embed_classic')         },
      { addon_plan: AddonPlan.get('embed', 'manual'),              plugin: App::Plugin.get('embed_flat')            },
      { addon_plan: AddonPlan.get('embed', 'manual'),              plugin: App::Plugin.get('embed_light')           },

      { addon_plan: AddonPlan.get('embed', 'auto'),                plugin: App::Plugin.get('embed_classic')         },
      { addon_plan: AddonPlan.get('embed', 'auto'),                plugin: App::Plugin.get('embed_flat')            },
      { addon_plan: AddonPlan.get('embed', 'auto'),                plugin: App::Plugin.get('embed_light')           },

      { addon_plan: AddonPlan.get('preview_tools', 'standard'),    plugin: App::Plugin.get('preview_tools_svnet') },

      { addon_plan: AddonPlan.get('end_actions', 'standard'),      plugin: App::Plugin.get('end_actions_twit')    },

      { addon_plan: AddonPlan.get('buy_action', 'standard'),       plugin: App::Plugin.get('buy_action_blizzard') },
      { addon_plan: AddonPlan.get('buy_action', 'standard'),       plugin: App::Plugin.get('buy_action_psg') },

      { addon_plan: AddonPlan.get('cuezones', 'standard'),         plugin: App::Plugin.get('cuezones') },

      { addon_plan: AddonPlan.get('google_analytics', 'standard'), plugin: App::Plugin.get('google_analytics') },

      { addon_plan: AddonPlan.get('dmt_controls', 'standard'), plugin: App::Plugin.get('dmt_controls') },
      { addon_plan: AddonPlan.get('dmt_quality', 'standard'),  plugin: App::Plugin.get('dmt_quality') },
      { addon_plan: AddonPlan.get('dmt_logo', 'standard'),     plugin: App::Plugin.get('dmt_logo') },
      { addon_plan: AddonPlan.get('dmt_sharing', 'standard'),  plugin: App::Plugin.get('dmt_sharing') },

      { addon_plan: AddonPlan.get('psg_controls', 'standard'), plugin: App::Plugin.get('psg_controls') },
      { addon_plan: AddonPlan.get('psg_logo', 'standard'),     plugin: App::Plugin.get('psg_logo') },

      { addon_plan: AddonPlan.get('rng_controls', 'standard'), plugin: App::Plugin.get('rng_controls') }
    ]
  end

end
