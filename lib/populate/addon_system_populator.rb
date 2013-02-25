class AddonSystemPopulator < Populator

  def execute
    PopulateHelpers.empty_tables(App::Component, App::ComponentVersion, App::Plugin, App::SettingsTemplate, App::Design, Addon, AddonPlan, BillableItem, BillableItemActivity)

    [App::Component, App::ComponentVersion, App::Design, Addon, App::Plugin, AddonPlan, App::SettingsTemplate].each do |klass, new_records|
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
      { name: 'blizzard', token: 'aca' }
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

  def app_design_seeds
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
      { name: 'blizzard', skin_token: 'aca.aca.aca', price: 0, availability: 'custom', stable_at: Time.now.utc, component: App::Component.get('blizzard') }
    ]
  end

  def addon_seeds
    [
        lambda { { name: 'video_player',   kind: 'videoPlayer',   design_dependent: false, parent_addon: nil } },
        lambda { { name: 'controls',       kind: 'controls',      design_dependent: true,  parent_addon: Addon.get('video_player') } },
        lambda { { name: 'initial',        kind: 'initial',       design_dependent: true,  parent_addon: Addon.get('video_player') } },
        lambda { { name: 'sharing',        kind: 'sharing',       design_dependent: true,  parent_addon: Addon.get('video_player') } },
        lambda { { name: 'social_sharing', kind: 'sharing',       design_dependent: true,  parent_addon: Addon.get('video_player') } },
        lambda { { name: 'embed',          kind: 'embed',         design_dependent: true,  parent_addon: Addon.get('video_player') } },
        lambda { { name: 'image_viewer',   kind: 'imageViewer',   design_dependent: false, parent_addon: nil } },
        lambda { { name: 'logo',           kind: 'logo',          design_dependent: false, parent_addon: Addon.get('video_player') } },
        lambda { { name: 'lightbox',       kind: 'lightbox',      design_dependent: true,  parent_addon: nil } },
        lambda { { name: 'api',            kind: 'api',           design_dependent: false, parent_addon: nil } },
        lambda { { name: 'stats',          kind: 'stats',         design_dependent: false, parent_addon: nil } },
        lambda { { name: 'support',        kind: 'support',       design_dependent: false, parent_addon: nil } },
        lambda { { name: 'preview_tools',  kind: 'previewTools',  design_dependent: false, parent_addon: nil } },
        lambda { { name: 'buy_action',     kind: 'buyAction',     design_dependent: true,  parent_addon: Addon.get('video_player') } },
        lambda { { name: 'action',         kind: 'action',        design_dependent: false, parent_addon: Addon.get('video_player') } },
        lambda { { name: 'end_actions',    kind: 'endActions',    design_dependent: true,  parent_addon: Addon.get('video_player') } },
        lambda { { name: 'info',           kind: 'info',          design_dependent: true,  parent_addon: Addon.get('video_player')  }}
    ]
  end

  def addon_plan_seeds
    [
      { name: 'standard',  price: 0,    addon: Addon.get('video_player'),   availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('lightbox'),       availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('image_viewer'),   availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('preview_tools'),  availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('end_actions'),    availability: 'custom', stable_at: Time.now.utc },
      { name: 'invisible', price: 0,    addon: Addon.get('stats'),          availability: 'hidden', stable_at: Time.now.utc },
      { name: 'realtime',  price: 990,  addon: Addon.get('stats'),          availability: 'public', stable_at: Time.now.utc },
      { name: 'sublime',   price: 0,    addon: Addon.get('logo'),           availability: 'public', stable_at: Time.now.utc },
      { name: 'disabled',  price: 990,  addon: Addon.get('logo'),           availability: 'public', stable_at: Time.now.utc },
      { name: 'custom',    price: 1990, addon: Addon.get('logo'),           availability: 'public', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('controls'),       availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('initial'),        availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('sharing'),        availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 690,  addon: Addon.get('social_sharing'), availability: 'public', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('embed'),          availability: 'public', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('api'),            availability: 'hidden', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('support'),        availability: 'public', stable_at: Time.now.utc },
      { name: 'vip',       price: 9990, addon: Addon.get('support'),        availability: 'public', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('buy_action'),     availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('info'),           availability: 'custom', stable_at: Time.now.utc },
      { name: 'standard',  price: 0,    addon: Addon.get('action'),         availability: 'custom', stable_at: Time.now.utc }
    ]
  end

  def app_plugin_seeds
    [
      { name: 'video_player',           token: 'sa.sh.si',    addon: Addon.get('video_player'),   design: nil,                         component: App::Component.get('app') },

      { name: 'lightbox_classic',       token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('classic'),  component: App::Component.get('app') },
      { name: 'lightbox_flat',          token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('flat'),     component: App::Component.get('app') },
      { name: 'lightbox_light',         token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('light'),    component: App::Component.get('app') },
      { name: 'lightbox_twit',          token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('twit'),     component: App::Component.get('app') },
      { name: 'lightbox_html5',         token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('html5'),    component: App::Component.get('app') },
      { name: 'lightbox_sony',          token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('sony'),     component: App::Component.get('app') },
      { name: 'lightbox_anthony',       token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('anthony'),  component: App::Component.get('app') },
      { name: 'lightbox_next15',        token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('next15'),   component: App::Component.get('app') },
      { name: 'lightbox_df',            token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('df'),       component: App::Component.get('app') },
      { name: 'lightbox_blizzard',      token: 'sa.sl.sm',    addon: Addon.get('lightbox'),       design: App::Design.get('blizzard'), component: App::Component.get('app') },

      { name: 'image_viewer',           token: 'sa.sn.so',    addon: Addon.get('image_viewer'),   design: nil,                         component: App::Component.get('app') },

      { name: 'logo',                   token: 'sa.sh.sp',    addon: Addon.get('logo'),           design: nil,                         component: App::Component.get('app') },

      { name: 'controls_classic',       token: 'sa.sh.sq',    addon: Addon.get('controls'),       design: App::Design.get('classic'),  component: App::Component.get('app') },
      { name: 'controls_flat',          token: 'sd.sd.sr',    addon: Addon.get('controls'),       design: App::Design.get('flat'),     component: App::Component.get('app') },
      { name: 'controls_light',         token: 'se.se.ss',    addon: Addon.get('controls'),       design: App::Design.get('light'),    component: App::Component.get('app') },
      { name: 'controls_twit',          token: 'sf.sf.st',    addon: Addon.get('controls'),       design: App::Design.get('twit'),     component: App::Component.get('twit') },
      { name: 'controls_html5',         token: 'sg.sg.su',    addon: Addon.get('controls'),       design: App::Design.get('html5'),    component: App::Component.get('html5') },
      { name: 'controls_sony',          token: 'tj.tj.sx',    addon: Addon.get('controls'),       design: App::Design.get('sony'),     component: App::Component.get('sony') },
      { name: 'controls_anthony',       token: 'aaa.aaa.aab', addon: Addon.get('controls'),       design: App::Design.get('anthony'),  component: App::Component.get('anthony') },
      { name: 'controls_next15',        token: 'aba.aba.abb', addon: Addon.get('controls'),       design: App::Design.get('next15'),   component: App::Component.get('next15') },
      { name: 'controls_df',            token: 'afa.afa.afb', addon: Addon.get('controls'),       design: App::Design.get('df'),       component: App::Component.get('df') },
      { name: 'controls_blizzard',      token: 'aca.aca.acd', addon: Addon.get('controls'),       design: App::Design.get('blizzard'), component: App::Component.get('blizzard') },

      { name: 'initial_classic',        token: 'sa.sh.sv',    addon: Addon.get('initial'),        design: App::Design.get('classic'),  component: App::Component.get('app') },
      { name: 'initial_flat',           token: 'sa.sh.sv',    addon: Addon.get('initial'),        design: App::Design.get('flat'),     component: App::Component.get('app') },
      { name: 'initial_light',          token: 'sa.sh.sv',    addon: Addon.get('initial'),        design: App::Design.get('light'),    component: App::Component.get('app') },
      { name: 'initial_twit',           token: 'sa.sh.sv',    addon: Addon.get('initial'),        design: App::Design.get('twit'),     component: App::Component.get('app') },
      { name: 'initial_html5',          token: 'sa.sh.sv',    addon: Addon.get('initial'),        design: App::Design.get('html5'),    component: App::Component.get('app') },
      { name: 'initial_sony',           token: 'tj.tj.sy',    addon: Addon.get('initial'),        design: App::Design.get('sony'),     component: App::Component.get('sony') },
      { name: 'initial_anthony',        token: 'sa.sh.sv',    addon: Addon.get('initial'),        design: App::Design.get('anthony'),  component: App::Component.get('app') },
      { name: 'initial_next15',         token: 'sa.sh.sv',    addon: Addon.get('initial'),        design: App::Design.get('next15'),   component: App::Component.get('app') },
      { name: 'initial_df',             token: 'sa.sh.sv',    addon: Addon.get('initial'),        design: App::Design.get('df'),       component: App::Component.get('app') },
      { name: 'initial_blizzard',       token: 'aca.aca.acc', addon: Addon.get('initial'),        design: App::Design.get('blizzard'), component: App::Component.get('blizzard') },

      { name: 'sharing_classic',        token: 'sa.sh.sz',    addon: Addon.get('sharing'),        design: App::Design.get('classic'),  component: App::Component.get('app') },
      { name: 'sharing_twit',           token: 'sa.sh.sz',    addon: Addon.get('sharing'),        design: App::Design.get('twit'),     component: App::Component.get('app') },
      { name: 'sharing_html5',          token: 'sa.sh.sz',    addon: Addon.get('sharing'),        design: App::Design.get('html5'),    component: App::Component.get('app') },
      { name: 'sharing_next15',         token: 'aba.aba.abc', addon: Addon.get('sharing'),        design: App::Design.get('next15'),   component: App::Component.get('next15') },
      { name: 'sharing_blizzard',       token: 'sa.sh.sz',    addon: Addon.get('sharing'),        design: App::Design.get('blizzard'), component: App::Component.get('app') },
      { name: 'sharing_sony',           token: 'sa.sh.sz',    addon: Addon.get('sharing'),        design: App::Design.get('sony'),     component: App::Component.get('app') },

      { name: 'social_sharing_classic', token: 'sa.sh.ua',    addon: Addon.get('social_sharing'), design: App::Design.get('classic'),  component: App::Component.get('app') },
      { name: 'social_sharing_flat',    token: 'sa.sh.ua',    addon: Addon.get('social_sharing'), design: App::Design.get('flat'),     component: App::Component.get('app') },
      { name: 'social_sharing_light',   token: 'sa.sh.ua',    addon: Addon.get('social_sharing'), design: App::Design.get('light'),    component: App::Component.get('app') },

      { name: 'embed_classic',          token: 'sa.sh.ub',    addon: Addon.get('embed'),          design: App::Design.get('classic'),  component: App::Component.get('app') },
      { name: 'embed_flat',             token: 'sa.sh.ub',    addon: Addon.get('embed'),          design: App::Design.get('flat'),     component: App::Component.get('app') },
      { name: 'embed_light',            token: 'sa.sh.ub',    addon: Addon.get('embed'),          design: App::Design.get('light'),    component: App::Component.get('app') },

      { name: 'info_sony',              token: 'tj.tj.aeb',   addon: Addon.get('info'),           design: App::Design.get('sony'),     component: App::Component.get('sony') },


      { name: 'buy_action_blizzard',    token: 'aca.aca.acb', addon: Addon.get('buy_action'),     design: App::Design.get('blizzard'), component: App::Component.get('blizzard') },

      { name: 'preview_tools_svnet',    token: 'sj.sj.sk',    addon: Addon.get('preview_tools'),  design: nil,                         component: App::Component.get('svnet') },

      { name: 'end_actions_twit',       token: 'sf.sf.agb',   addon: Addon.get('end_actions'),    design: App::Design.get('twit'),     component: App::Component.get('twit') },

      { name: 'action_svnet',           token: 'sj.sj.adb',   addon: Addon.get('action'),         design: nil,                         component: App::Component.get('svnet') }
    ]
  end

  def app_settings_template_seeds
    [
      { addon_plan: AddonPlan.get('video_player', 'standard'),   plugin: App::Plugin.get('video_player')          },

      { addon_plan: AddonPlan.get('action', 'standard'),         plugin: App::Plugin.get('action_svnet')          },

      { addon_plan: AddonPlan.get('info', 'standard'),           plugin: App::Plugin.get('info_sony')             },

      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_classic')      },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_flat')         },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_light')        },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_twit')         },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_html5')        },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_sony')         },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_anthony')      },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_next15')       },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_df')           },
      { addon_plan: AddonPlan.get('controls', 'standard'),       plugin: App::Plugin.get('controls_blizzard')     },

      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_classic')      },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_flat'), suffix: 'without_close_button' },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_light'), suffix: 'without_close_button' },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_twit')         },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_html5')        },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_sony')         },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_anthony'), suffix: 'without_close_button' },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_next15')       },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_df')           },
      { addon_plan: AddonPlan.get('lightbox', 'standard'),       plugin: App::Plugin.get('lightbox_blizzard'), suffix: 'without_close_button' },

      { addon_plan: AddonPlan.get('image_viewer', 'standard'),   plugin: App::Plugin.get('image_viewer')          },

      { addon_plan: AddonPlan.get('stats', 'invisible'),         plugin: nil                                      },
      { addon_plan: AddonPlan.get('stats', 'realtime'),          plugin: nil                                      },

      { addon_plan: AddonPlan.get('logo', 'sublime'),            plugin: App::Plugin.get('logo')                  },
      { addon_plan: AddonPlan.get('logo', 'disabled'),           plugin: App::Plugin.get('logo')                  },
      { addon_plan: AddonPlan.get('logo', 'custom'),             plugin: App::Plugin.get('logo')                  },

      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_classic')       },
      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_flat')          },
      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_light')         },
      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_twit')          },
      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_html5')         },
      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_sony')          },
      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_anthony')       },
      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_next15')        },
      { addon_plan: AddonPlan.get('initial', 'standard'),        plugin: App::Plugin.get('initial_blizzard')      },

      { addon_plan: AddonPlan.get('sharing', 'standard'),        plugin: App::Plugin.get('sharing_classic')       },
      { addon_plan: AddonPlan.get('sharing', 'standard'),        plugin: App::Plugin.get('sharing_twit')          },
      { addon_plan: AddonPlan.get('sharing', 'standard'),        plugin: App::Plugin.get('sharing_html5')         },
      { addon_plan: AddonPlan.get('sharing', 'standard'),        plugin: App::Plugin.get('sharing_next15')        },
      { addon_plan: AddonPlan.get('sharing', 'standard'),        plugin: App::Plugin.get('sharing_blizzard')      },
      { addon_plan: AddonPlan.get('sharing', 'standard'),        plugin: App::Plugin.get('sharing_sony')          },

      { addon_plan: AddonPlan.get('social_sharing', 'standard'), plugin: App::Plugin.get('social_sharing_classic') },
      { addon_plan: AddonPlan.get('social_sharing', 'standard'), plugin: App::Plugin.get('social_sharing_flat')   },
      { addon_plan: AddonPlan.get('social_sharing', 'standard'), plugin: App::Plugin.get('social_sharing_light')  },

      { addon_plan: AddonPlan.get('embed', 'standard'),          plugin: App::Plugin.get('embed_classic')         },
      { addon_plan: AddonPlan.get('embed', 'standard'),          plugin: App::Plugin.get('embed_flat')            },
      { addon_plan: AddonPlan.get('embed', 'standard'),          plugin: App::Plugin.get('embed_light')           },

      { addon_plan: AddonPlan.get('preview_tools', 'standard'),  plugin: App::Plugin.get('preview_tools_svnet') },

      { addon_plan: AddonPlan.get('end_actions', 'standard'),    plugin: App::Plugin.get('end_actions_twit')    },

      { addon_plan: AddonPlan.get('buy_action', 'standard'),     plugin: App::Plugin.get('buy_action_blizzard') }
    ]
  end

end
