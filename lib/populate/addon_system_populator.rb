class AddonSystemPopulator < Populator

  APP_COMPONENT_KEYS = [:name, :token]

  APP_COMPONENT_SEEDS = -> { [
    ['app',      'sa'],
    ['twit',     'sf'],
    ['html5',    'sg'],
    ['sony',     'tj'],
    ['svnet',    'sj'],
    ['anthony',  'aaa'],
    ['next15',   'aba'],
    ['df',       'afa'],
    ['blizzard', 'aca'],
    ['daily',    'aha'],
    ['psg',      'aja'],
    ['orange',   'aia']
  ] }

  APP_COMPONENT_VERSION_KEYS = [:component, :version, :zip]

  APP_COMPONENT_VERSION_SEEDS = -> { [
    [App::Component.get('app'),   '1.0.0', File.new(Rails.root.join('spec/fixtures/app/e.zip'))],
    [App::Component.get('twit'),  '1.0.0', File.new(Rails.root.join('spec/fixtures/app/e.zip'))],
    [App::Component.get('html5'), '1.0.0', File.new(Rails.root.join('spec/fixtures/app/e.zip'))],
    [App::Component.get('svnet'), '1.0.0', File.new(Rails.root.join('spec/fixtures/app/e.zip'))]
  ] }

  DESIGN_KEYS = [:name, :skin_mod, :skin_token, :price, :availability, :stable_at, :component]

  DESIGN_SEEDS = -> { [
    ['classic',  'sublime/sublime_skin',           'sa.sb.sc',    0, 'public', Time.now.utc, App::Component.get('app')],
    ['flat',     'players/flat/flat_skin',         'sa.sd.sd',    0, 'public', Time.now.utc, App::Component.get('app')],
    ['light',    'players/light/light_skin',       'sa.se.se',    0, 'public', Time.now.utc, App::Component.get('app')],
    ['twit',     'players/twit/twit_skin',         'sf.sf.sf',    0, 'custom', Time.now.utc, App::Component.get('twit')],
    ['html5',    'players/html5/html5_skin',       'sg.sg.sg',    0, 'custom', Time.now.utc, App::Component.get('html5')],
    ['sony',     'players/sony/sony_skin',         'tj.tj.tj',    0, 'custom', Time.now.utc, App::Component.get('sony')],
    ['svnet',    'sublime/sublime_skin',           'sj.sj.sj',    0, 'custom', Time.now.utc, App::Component.get('svnet')],
    ['anthony',  'players/anthony/anthony_skin',   'aaa.aaa.aaa', 0, 'custom', Time.now.utc, App::Component.get('anthony')],
    ['next15',   'players/next15/next15_skin',     'aba.aba.aba', 0, 'custom', Time.now.utc, App::Component.get('next15')],
    ['df',       'players/df/df_skin',             'afa.afa.afa', 0, 'custom', Time.now.utc, App::Component.get('df')],
    ['blizzard', 'players/blizzard/blizzard_skin', 'aca.aca.aca', 0, 'custom', Time.now.utc, App::Component.get('blizzard')],
    ['daily',    'players/daily/daily_skin',       'aha.aha.aha', 0, 'custom', Time.now.utc, App::Component.get('daily')],
    ['psg',      'players/psg/psg_skin',           'aja.aja.aja', 0, 'custom', Time.now.utc, App::Component.get('psg')],
    ['orange',   'players/orange/orange_skin',     'aia.aia.aia', 0, 'custom', Time.now.utc, App::Component.get('orange')]
  ] }

  ADDON_KEYS = [:name, :kind, :design_dependent, :parent_addon_id]

  ADDON_SEEDS = -> { [
    -> { ['video_player',     'videoPlayer',     false, nil] },
    -> { ['controls',         'controls',        true,  Addon.get('video_player').id] },
    -> { ['initial',          'initial',         true,  Addon.get('video_player').id] },
    -> { ['sharing',          'sharing',         true,  Addon.get('video_player').id] },
    -> { ['social_sharing',   'sharing',         true,  Addon.get('video_player').id] },
    -> { ['embed',            'embed',           true,  Addon.get('video_player').id] },
    -> { ['image_viewer',     'imageViewer',     false, nil] },
    -> { ['logo',             'logo',            false, Addon.get('video_player').id] },
    -> { ['lightbox',         'lightbox',        true,  nil] },
    -> { ['api',              'api',             false, nil] },
    -> { ['stats',            'stats',           false, nil] },
    -> { ['support',          'support',         false, nil] },
    -> { ['preview_tools',    'previewTools',    false, nil] },
    -> { ['buy_action',       'buyAction',       true,  Addon.get('video_player').id] },
    -> { ['action',           'action',          false, Addon.get('video_player').id] },
    -> { ['end_actions',      'endActions',      true,  Addon.get('video_player').id] },
    -> { ['info',             'info',            true,  Addon.get('video_player').id] },
    -> { ['cuezones',         'cuezones',        false, Addon.get('video_player').id] },
    -> { ['google_analytics', 'googleAnalytics', false, Addon.get('video_player').id] },
    -> { ['dmt_controls',     'controls',        true,  Addon.get('video_player').id] },
    -> { ['dmt_quality',      'qualityPane',     true,  Addon.get('video_player').id] },
    -> { ['dmt_logo',         'logo',            true,  Addon.get('video_player').id] },
    -> { ['dmt_sharing',      'sharing',         true,  Addon.get('video_player').id] },
    -> { ['psg_controls',     'controls',        true,  Addon.get('video_player').id] },
    -> { ['psg_logo',         'logo',            true,  Addon.get('video_player').id] },
    -> { ['rng_controls',     'controls',        true,  Addon.get('video_player').id] }
  ] }

  ADDON_PLAN_KEYS = [:name, :price, :addon, :availability, :stable_at]

  ADDON_PLAN_SEEDS = -> { [
    ['standard',  0,    Addon.get('video_player'),     'hidden', Time.now.utc],
    ['standard',  0,    Addon.get('lightbox'),         'hidden', Time.now.utc],
    ['standard',  0,    Addon.get('image_viewer'),     'hidden', Time.now.utc],
    ['standard',  0,    Addon.get('preview_tools'),    'custom', Time.now.utc],
    ['standard',  0,    Addon.get('end_actions'),      'custom', Time.now.utc],
    ['invisible', 0,    Addon.get('stats'),            'hidden', Time.now.utc],
    ['realtime',  990,  Addon.get('stats'),            'public', Time.now.utc],
    ['sublime',   0,    Addon.get('logo'),             'public', Time.now.utc],
    ['disabled',  990,  Addon.get('logo'),             'public', Time.now.utc],
    ['custom',    1990, Addon.get('logo'),             'public', Time.now.utc],
    ['standard',  0,    Addon.get('controls'),         'hidden', Time.now.utc],
    ['standard',  0,    Addon.get('initial'),          'hidden', Time.now.utc],
    ['standard',  0,    Addon.get('sharing'),          'custom', Time.now.utc],
    ['standard',  690,  Addon.get('social_sharing'),   'public', Time.now.utc],
    ['manual',    0,    Addon.get('embed'),            'public', Time.now.utc],
    ['auto',      990,  Addon.get('embed'),            'public', Time.now.utc],
    ['standard',  0,    Addon.get('api'),              'hidden', Time.now.utc],
    ['standard',  0,    Addon.get('support'),          'public', Time.now.utc],
    ['vip',       9990, Addon.get('support'),          'public', Time.now.utc],
    ['standard',  0,    Addon.get('buy_action'),       'custom', Time.now.utc],
    ['standard',  0,    Addon.get('info'),             'custom', Time.now.utc],
    ['standard',  0,    Addon.get('action'),           'custom', Time.now.utc],
    ['standard',  690,  Addon.get('cuezones'),         'public', Time.now.utc],
    ['standard',  690,  Addon.get('google_analytics'), 'public', Time.now.utc],
    ['standard',  0,    Addon.get('dmt_controls'),     'custom', Time.now.utc],
    ['standard',  0,    Addon.get('dmt_quality'),      'custom', Time.now.utc],
    ['standard',  0,    Addon.get('dmt_logo'),         'custom', Time.now.utc],
    ['standard',  0,    Addon.get('dmt_sharing'),      'custom', Time.now.utc],
    ['standard',  0,    Addon.get('psg_controls'),     'custom', Time.now.utc],
    ['standard',  0,    Addon.get('psg_logo'),         'custom', Time.now.utc],
    ['standard',  0,    Addon.get('rng_controls'),     'custom', Time.now.utc]
  ] }

  APP_PLUGIN_KEYS = [:name, :mod, :token, :addon, :design, :component]

  APP_PLUGIN_SEEDS = -> { [
    ['video_player',           'sublime/video/video_app_plugin',                                     'sa.sh.si',    Addon.get('video_player'),     nil,                    App::Component.get('app')],
    ['lightbox_classic',       'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('classic'),  App::Component.get('app')],
    ['lightbox_flat',          'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('flat'),     App::Component.get('app')],
    ['lightbox_light',         'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('light'),    App::Component.get('app')],
    ['lightbox_twit',          'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('twit'),     App::Component.get('app')],
    ['lightbox_html5',         'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('html5'),    App::Component.get('app')],
    ['lightbox_sony',          'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('sony'),     App::Component.get('app')],
    ['lightbox_anthony',       'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('anthony'),  App::Component.get('app')],
    ['lightbox_next15',        'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('next15'),   App::Component.get('app')],
    ['lightbox_df',            'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('df'),       App::Component.get('app')],
    ['lightbox_blizzard',      'sublime/lightbox/lightbox_app_plugin',                               'sa.sl.sm',    Addon.get('lightbox'),         Design.get('blizzard'), App::Component.get('app')],
    ['image_viewer',           'sublime/image/image_app_plugin',                                     'sa.sn.so',    Addon.get('image_viewer'),     nil,                    App::Component.get('app')],
    ['logo',                   'sublime/video/plugins/logo/logo',                                    'sa.sh.sp',    Addon.get('logo'),             nil,                    App::Component.get('app')],
    ['controls_classic',       'sublime/video/plugins/controls/controls',                            'sa.sh.sq',    Addon.get('controls'),         Design.get('classic'),  App::Component.get('app')],
    ['controls_flat',          'players/flat/plugins/controls/controls',                             'sd.sd.sr',    Addon.get('controls'),         Design.get('flat'),     App::Component.get('app')],
    ['controls_light',         'players/light/plugins/controls/controls',                            'se.se.ss',    Addon.get('controls'),         Design.get('light'),    App::Component.get('app')],
    ['controls_twit',          'players/twit/plugins/controls/controls',                             'sf.sf.st',    Addon.get('controls'),         Design.get('twit'),     App::Component.get('twit')],
    ['controls_html5',         'players/html5/plugins/controls/controls',                            'sg.sg.su',    Addon.get('controls'),         Design.get('html5'),    App::Component.get('html5')],
    ['controls_sony',          'players/sony/plugins/controls/controls',                             'tj.tj.sx',    Addon.get('controls'),         Design.get('sony'),     App::Component.get('sony')],
    ['controls_anthony',       'players/anthony/plugins/controls/controls',                          'aaa.aaa.aab', Addon.get('controls'),         Design.get('anthony'),  App::Component.get('anthony')],
    ['controls_next15',        'players/next15/plugins/controls/controls',                           'aba.aba.abb', Addon.get('controls'),         Design.get('next15'),   App::Component.get('next15')],
    ['controls_df',            'players/df/plugins/controls/controls',                               'afa.afa.afb', Addon.get('controls'),         Design.get('df'),       App::Component.get('df')],
    ['controls_blizzard',      'players/blizzard/plugins/controls/controls',                         'aca.aca.acd', Addon.get('controls'),         Design.get('blizzard'), App::Component.get('blizzard')],
    ['initial_classic',        'sublime/video/plugins/poster/start_controller',                      'sa.sh.sv',    Addon.get('initial'),          Design.get('classic'),  App::Component.get('app')],
    ['initial_flat',           'sublime/video/plugins/poster/start_controller',                      'sa.sh.sv',    Addon.get('initial'),          Design.get('flat'),     App::Component.get('app')],
    ['initial_light',          'sublime/video/plugins/poster/start_controller',                      'sa.sh.sv',    Addon.get('initial'),          Design.get('light'),    App::Component.get('app')],
    ['initial_twit',           'sublime/video/plugins/poster/start_controller',                      'sa.sh.sv',    Addon.get('initial'),          Design.get('twit'),     App::Component.get('app')],
    ['initial_html5',          'sublime/video/plugins/poster/start_controller',                      'sa.sh.sv',    Addon.get('initial'),          Design.get('html5'),    App::Component.get('app')],
    ['initial_sony',           'players/sony/plugins/poster/start_controller',                       'tj.tj.sy',    Addon.get('initial'),          Design.get('sony'),     App::Component.get('sony')],
    ['initial_anthony',        'sublime/video/plugins/poster/start_controller',                      'sa.sh.sv',    Addon.get('initial'),          Design.get('anthony'),  App::Component.get('app')],
    ['initial_next15',         'sublime/video/plugins/poster/start_controller',                      'sa.sh.sv',    Addon.get('initial'),          Design.get('next15'),   App::Component.get('app')],
    ['initial_df',             'sublime/video/plugins/poster/start_controller',                      'sa.sh.sv',    Addon.get('initial'),          Design.get('df'),       App::Component.get('app')],
    ['initial_blizzard',       'players/blizzard/plugins/poster/start_controller',                   'aca.aca.acc', Addon.get('initial'),          Design.get('blizzard'), App::Component.get('blizzard')],
    ['sharing_classic',        'sublime/video/plugins/sharing/sharing_buttons' ,                     'sa.sh.sz',    Addon.get('sharing'),          Design.get('classic'),  App::Component.get('app')],
    ['sharing_twit',           'sublime/video/plugins/sharing/sharing_buttons' ,                     'sa.sh.sz',    Addon.get('sharing'),          Design.get('twit'),     App::Component.get('app')],
    ['sharing_html5',          'sublime/video/plugins/sharing/sharing_buttons' ,                     'sa.sh.sz',    Addon.get('sharing'),          Design.get('html5'),    App::Component.get('app')],
    ['sharing_next15',         'players/next15/plugins/sharing/sharing_buttons',                     'aba.aba.abc', Addon.get('sharing'),          Design.get('next15'),   App::Component.get('next15')],
    ['sharing_blizzard',       'sublime/video/plugins/sharing/sharing_buttons' ,                     'sa.sh.sz',    Addon.get('sharing'),          Design.get('blizzard'), App::Component.get('app')],
    ['sharing_sony',           'sublime/video/plugins/sharing/sharing_buttons' ,                     'sa.sh.sz',    Addon.get('sharing'),          Design.get('sony'),     App::Component.get('app')],
    ['sharing_psg',            'sublime/video/plugins/sharing/sharing_buttons' ,                     'sa.sh.sz',    Addon.get('sharing'),          Design.get('psg'),      App::Component.get('app')],
    ['sharing_orange',         'sublime/video/plugins/sharing/sharing_buttons' ,                     'sa.sh.sz',    Addon.get('sharing'),          Design.get('orange'),   App::Component.get('app')],
    ['social_sharing_classic', 'sublime/video/plugins/social_sharing/social_sharing',                'sa.sh.ua',    Addon.get('social_sharing'),   Design.get('classic'),  App::Component.get('app')],
    ['social_sharing_flat',    'sublime/video/plugins/social_sharing/social_sharing',                'sa.sh.ua',    Addon.get('social_sharing'),   Design.get('flat'),     App::Component.get('app')],
    ['social_sharing_light',   'sublime/video/plugins/social_sharing/social_sharing',                'sa.sh.ua',    Addon.get('social_sharing'),   Design.get('light'),    App::Component.get('app')],
    ['embed_classic',          'sublime/video/plugins/embed/embed',                                  'sa.sh.ub',    Addon.get('embed'),            Design.get('classic'),  App::Component.get('app')],
    ['embed_flat',             'sublime/video/plugins/embed/embed',                                  'sa.sh.ub',    Addon.get('embed'),            Design.get('flat'),     App::Component.get('app')],
    ['embed_light',            'sublime/video/plugins/embed/embed',                                  'sa.sh.ub',    Addon.get('embed'),            Design.get('light'),    App::Component.get('app')],
    ['info_sony',              'players/sony/plugins/info/info_controller',                          'tj.tj.aeb',   Addon.get('info'),             Design.get('sony'),     App::Component.get('sony')],
    ['buy_action_blizzard',    'players/blizzard/plugins/buy/buy_controller',                        'aca.aca.acb', Addon.get('buy_action'),       Design.get('blizzard'), App::Component.get('blizzard')],
    ['buy_action_psg',         'players/psg/plugins/buy/buy_controller',                             'aja.aja.ajd', Addon.get('buy_action'),       Design.get('psg'),      App::Component.get('psg')],
    ['preview_tools_svnet',    'players/svnet/plugins/extended_video_app/extended_video_app_plugin', 'sj.sj.sk',    Addon.get('preview_tools'),    nil,                    App::Component.get('svnet')],
    ['end_actions_twit',       'players/twit/plugins/actions/action_buttons',                        'sf.sf.agb',   Addon.get('end_actions'),      Design.get('twit'),     App::Component.get('twit')],
    ['action_svnet',           'players/svnet/plugins/actions/action_buttons',                       'sj.sj.adb',   Addon.get('action'),           nil,                    App::Component.get('svnet')],
    ['cuezones',               'sublime/video/plugins/cuepoints/cue_zones',                          'sa.sh.ud',    Addon.get('cuezones'),         nil,                    App::Component.get('app')],
    ['google_analytics',       'sublime/video/plugins/google_analytics/google_analytics',            'sa.sh.uf',    Addon.get('google_analytics'), nil,                    App::Component.get('app')],
    ['dmt_controls',           'players/daily/plugins/controls/controls',                            'aha.aha.ahb', Addon.get('dmt_controls'),     Design.get('daily'),    App::Component.get('daily')],
    ['dmt_quality',            'players/daily/plugins/quality/quality',                              'aha.aha.ahc', Addon.get('dmt_quality'),      Design.get('daily'),    App::Component.get('daily')],
    ['dmt_logo',               'players/daily/plugins/logo/logo',                                    'aha.aha.ahd', Addon.get('dmt_logo'),         Design.get('daily'),    App::Component.get('daily')],
    ['dmt_sharing',            'players/daily/plugins/sharing/sharing_buttons',                      'aha.aha.ahe', Addon.get('dmt_sharing'),      Design.get('daily'),    App::Component.get('daily')],
    ['psg_controls',           'players/psg/plugins/controls/controls',                              'aja.aja.ajb', Addon.get('psg_controls'),     Design.get('psg'),      App::Component.get('psg')],
    ['psg_logo',               'players/psg/plugins/logo/logo',                                      'aja.aja.ajc', Addon.get('psg_logo'),         Design.get('psg'),      App::Component.get('psg')],
    ['rng_controls',           'players/orange/plugins/controls/controls',                           'aia.aia.aib', Addon.get('rng_controls'),     Design.get('orange'),   App::Component.get('orange')]
  ] }

  ADDON_PLAN_SETTINGS_KEYS = [:addon_plan, :plugin, :suffix]

  ADDON_PLAN_SETTINGS_SEEDS = -> { [
    [AddonPlan.get('video_player', 'standard'),     App::Plugin.get('video_player'),           nil],
    [AddonPlan.get('action', 'standard'),           App::Plugin.get('action_svnet'),           nil],
    [AddonPlan.get('info', 'standard'),             App::Plugin.get('info_sony'),              nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_classic'),       nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_flat'),          nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_light'),         nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_twit'),          nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_html5'),         nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_sony'),          nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_anthony'),       nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_next15'),        nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_df'),            nil],
    [AddonPlan.get('controls', 'standard'),         App::Plugin.get('controls_blizzard'),      nil],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_classic'),       nil],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_flat'),          'without_close_button'],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_light'),         'without_close_button'],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_twit'),          nil],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_html5'),         nil],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_sony'),          nil],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_anthony'),       'without_close_button'],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_next15'),        nil],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_df'),            nil],
    [AddonPlan.get('lightbox', 'standard'),         App::Plugin.get('lightbox_blizzard'),      'without_close_button'],
    [AddonPlan.get('image_viewer', 'standard'),     App::Plugin.get('image_viewer'),           nil],
    [AddonPlan.get('stats', 'invisible'),           nil,                                       nil],
    [AddonPlan.get('stats', 'realtime'),            nil,                                       nil],
    [AddonPlan.get('logo', 'sublime'),              App::Plugin.get('logo'),                   nil],
    [AddonPlan.get('logo', 'disabled'),             App::Plugin.get('logo'),                   nil],
    [AddonPlan.get('logo', 'custom'),               App::Plugin.get('logo'),                   nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_classic'),        nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_flat'),           nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_light'),          nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_twit'),           nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_html5'),          nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_sony'),           nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_anthony'),        nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_next15'),         nil],
    [AddonPlan.get('initial', 'standard'),          App::Plugin.get('initial_blizzard'),       nil],
    [AddonPlan.get('sharing', 'standard'),          App::Plugin.get('sharing_classic'),        nil],
    [AddonPlan.get('sharing', 'standard'),          App::Plugin.get('sharing_twit'),           nil],
    [AddonPlan.get('sharing', 'standard'),          App::Plugin.get('sharing_html5'),          nil],
    [AddonPlan.get('sharing', 'standard'),          App::Plugin.get('sharing_next15'),         nil],
    [AddonPlan.get('sharing', 'standard'),          App::Plugin.get('sharing_blizzard'),       nil],
    [AddonPlan.get('sharing', 'standard'),          App::Plugin.get('sharing_sony'),           nil],
    [AddonPlan.get('sharing', 'standard'),          App::Plugin.get('sharing_psg'),            nil],
    [AddonPlan.get('sharing', 'standard'),          App::Plugin.get('sharing_orange'),         nil],
    [AddonPlan.get('social_sharing', 'standard'),   App::Plugin.get('social_sharing_classic'), nil],
    [AddonPlan.get('social_sharing', 'standard'),   App::Plugin.get('social_sharing_flat'),    nil],
    [AddonPlan.get('social_sharing', 'standard'),   App::Plugin.get('social_sharing_light'),   nil],
    [AddonPlan.get('embed', 'manual'),              App::Plugin.get('embed_classic'),          nil],
    [AddonPlan.get('embed', 'manual'),              App::Plugin.get('embed_flat'),             nil],
    [AddonPlan.get('embed', 'manual'),              App::Plugin.get('embed_light'),            nil],
    [AddonPlan.get('embed', 'auto'),                App::Plugin.get('embed_classic'),          nil],
    [AddonPlan.get('embed', 'auto'),                App::Plugin.get('embed_flat'),             nil],
    [AddonPlan.get('embed', 'auto'),                App::Plugin.get('embed_light'),            nil],
    [AddonPlan.get('preview_tools', 'standard'),    App::Plugin.get('preview_tools_svnet'),    nil],
    [AddonPlan.get('end_actions', 'standard'),      App::Plugin.get('end_actions_twit'),       nil],
    [AddonPlan.get('buy_action', 'standard'),       App::Plugin.get('buy_action_blizzard'),    nil],
    [AddonPlan.get('buy_action', 'standard'),       App::Plugin.get('buy_action_psg'),         nil],
    [AddonPlan.get('cuezones', 'standard'),         App::Plugin.get('cuezones'),               nil],
    [AddonPlan.get('google_analytics', 'standard'), App::Plugin.get('google_analytics'),       nil],
    [AddonPlan.get('dmt_controls', 'standard'),     App::Plugin.get('dmt_controls'),           nil],
    [AddonPlan.get('dmt_quality', 'standard'),      App::Plugin.get('dmt_quality'),            nil],
    [AddonPlan.get('dmt_logo', 'standard'),         App::Plugin.get('dmt_logo'),               nil],
    [AddonPlan.get('dmt_sharing', 'standard'),      App::Plugin.get('dmt_sharing'),            nil],
    [AddonPlan.get('psg_controls', 'standard'),     App::Plugin.get('psg_controls'),           nil],
    [AddonPlan.get('psg_logo', 'standard'),         App::Plugin.get('psg_logo'),               nil],
    [AddonPlan.get('rng_controls', 'standard'),     App::Plugin.get('rng_controls'),           nil]
  ] }

  def execute
    PopulateHelpers.empty_tables(App::Component, App::ComponentVersion, App::Plugin, AddonPlanSettings, Design, Addon, AddonPlan, BillableItem, BillableItemActivity)

    [App::Component, App::ComponentVersion, Design, Addon, App::Plugin, AddonPlan, AddonPlanSettings].each do |klass|
      _plant_seeds_for_class(klass)

      puts "\t- #{klass.count} #{klass} created;" unless Rails.env.test?
    end
  end

  private

  def _upcase_klass_name(klass)
    klass.to_s.underscore.gsub('/', '_').upcase
  end

  def _get_attributes_hash_for_class(attrs, klass)
    attrs = attrs.call if attrs.respond_to?(:call)

    Hash[self.class.const_get("#{_upcase_klass_name(klass)}_KEYS").zip(attrs)]
  end

  def _plant_seeds_for_class(klass)
    self.class.const_get("#{_upcase_klass_name(klass)}_SEEDS").call.each do |attrs|
      attributes = _get_attributes_hash_for_class(attrs, klass)

      populator_class = "#{klass.to_s.demodulize}Populator"
      if Object.const_defined?(populator_class)
        populator = populator_class.constantize.new(attributes)
        populator.execute
      else
        klass.create(attributes, without_protection: true)
      end
    end
  end

end
