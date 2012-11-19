# coding: utf-8
require 'ffaker' if Rails.env.development?
require_dependency 'service/site'
require_dependency 'service/usage'
require_dependency 'service/invoice'

module Populate

  class << self

    BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"], ["Andrea Coiro", "andrea@jilion.com"]]
    COUNTRIES  = %w[US FR CH ES DE BE GB CN SE NO FI BR CA]
    BASE_SITES = %w[vimeo.com dribbble.com jilion.com swisslegacy.com maxvoltar.com 37signals.com youtube.com zeldman.com sumagency.com deaxon.com veerle.duoh.com]

    def plans
      empty_tables(Plan)
      plans_attributes = [
        { name: "free",       cycle: "none",  video_views: 0,          stats_retention_days: 0,   price: 0,     support_level: 0 },
        { name: "sponsored",  cycle: "none",  video_views: 0,          stats_retention_days: nil, price: 0,     support_level: 0 },
        { name: "trial",      cycle: "none",  video_views: 0,          stats_retention_days: nil, price: 0,     support_level: 2 },
        { name: "plus",       cycle: "month", video_views: 200_000,    stats_retention_days: 365, price: 990,   support_level: 1 },
        { name: "premium",    cycle: "month", video_views: 1_000_000,  stats_retention_days: nil, price: 4990,  support_level: 2 },
        { name: "plus",       cycle: "year",  video_views: 200_000,    stats_retention_days: 365, price: 9900,  support_level: 1 },
        { name: "premium",    cycle: "year",  video_views: 1_000_000,  stats_retention_days: nil, price: 49900, support_level: 2 },
        { name: "custom - 1", cycle: "year",  video_views: 10_000_000, stats_retention_days: nil, price: 99900, support_level: 2 }
      ]
      plans_attributes.each { |attributes| Plan.create!(attributes) }
      puts "#{plans_attributes.size} plans created!"
    end

    def deals
      empty_tables(DealActivation, Deal)
      deals_attributes = [
        { token: 'rts1', name: 'Real-Time Stats promotion #1', description: 'Exclusive Newsletter Promotion: Save 20% on all yearly plans', kind: 'yearly_plans_discount', value: 0.2, availability_scope: 'newsletter', started_at: Time.now.utc.midnight, ended_at: Time.utc(2012, 2, 29).end_of_day },
        { token: 'rts2', name: 'Premium promotion #1', description: '30% discount on the Premium plan', kind: 'premium_plan_discount', value: 0.3, availability_scope: 'newsletter', started_at: 3.weeks.from_now.midnight, ended_at: 5.weeks.from_now.end_of_day }
      ]

      deals_attributes.each { |attributes| Deal.create!(attributes) }
      puts "#{deals_attributes.size} deals created!"
    end

    def addons
      empty_tables(App::Component, App::ComponentVersion, App::Plugin, App::SettingsTemplate, App::Design, Addon, AddonPlan, BillableItem, BillableItemActivity)

      lightbox_template = {
        on_open: {
          type: 'string',
          values: ['nothing', 'play'],
          default: 'play'
        },
        overlay_color: {
          type: 'color',
          values: ['#000'],
          default: '#000'
        },
        overlay_opacity: {
          type: 'float',
          range: [0.1, 1],
          step: 0.1,
          default: 0.7
        },
        enable_close_button: {
          type: 'boolean',
          values: [true, false],
          default: true
        },
        close_button_visibility: {
          type: 'string',
          values: ['autohide', 'visible'],
          default: 'autohide'
        },
        close_button_position: {
          type: 'string',
          values: ['left', 'right'],
          default: 'left'
        }
      }
      controls_template = {
        enable: {
          type: 'boolean',
          values: [true, false],
          default: true
        },
        visibility: {
          type: 'string',
          values: ['autohide', 'visible'],
          default: 'autohide'
        }
      }
      initial_template = {
        enable_overlay: {
          type: 'boolean',
          values: [true, false],
          default: true
        },
        overlay_visibility: {
          type: 'string',
          values: ['autofade', 'visible'],
          default: 'autofade'
        },
        overlay_color: {
          type: 'color',
          values: ['#000'],
          default: '#000'
        }
      }
      sharing_template = {
        enable_twitter: {
          type: 'boolean',
          values: [true, false],
          default: true
        },
        enable_facebook: {
          type: 'boolean',
          values: [true, false],
          default: true
        },
        enable_link: {
          type: 'boolean',
          values: [true, false],
          default: true
        },
        enable_embed: {
          type: 'boolean',
          values: [true, false],
          default: true
        },
        order: {
          type: 'string',
          default: 'twitter link facebook embed'
        },
        default_url: {
          type: 'url'
        },
        twitter_url: {
          type: 'url'
        },
        facebook_url: {
          type: 'url'
        },
        link_url: {
          type: 'url'
        },
        embed_url: {
          type: 'url'
        },
        embed_width: {
          type: 'size'
        },
        embed_height: {
          type: 'size'
        }
      }
      seeds = {
        App::Component => [
          { name: 'app', token: 'sa' },
          { name: 'twit', token: 'sf' },
          { name: 'html5', token: 'sg' },
          { name: 'svnet', token: 'sj' }
        ],
        App::Design => [
          { name: 'classic', skin_token: 'sa.sb.sc', price: 0, availability: 'public', component: 'ref-App::Component-app' },
          { name: 'flat',    skin_token: 'sa.sd.sd', price: 0, availability: 'public', required_stage: 'beta', component: 'ref-App::Component-app' },
          { name: 'light',   skin_token: 'sa.se.se', price: 0, availability: 'public', required_stage: 'beta', component: 'ref-App::Component-app' },
          { name: 'twit',    skin_token: 'sf.sf.sf', price: 0, availability: 'custom', required_stage: 'beta', component: 'ref-App::Component-twit' },
          { name: 'html5',   skin_token: 'sg.sg.sg', price: 0, availability: 'custom', required_stage: 'beta', component: 'ref-App::Component-html5' }
        ],
        Addon => [
          { name: 'video_player',   kind: 'videoPlayer', design_dependent: false, parent_addon: nil },
          { name: 'controls',       kind: 'controls',    design_dependent: true,  parent_addon: 'ref-Addon-video_player' },
          { name: 'initial',        kind: 'initial',     design_dependent: true,  parent_addon: 'ref-Addon-video_player' },
          { name: 'sharing',        kind: 'sharing',     design_dependent: true,  parent_addon: 'ref-Addon-video_player' },
          { name: 'image_viewer',   kind: 'imageViewer', design_dependent: false, parent_addon: nil },
          { name: 'logo',           kind: 'logo',        design_dependent: false, parent_addon: 'ref-Addon-video_player' },
          { name: 'lightbox',       kind: 'lightbox',    design_dependent: true,  parent_addon: nil },
          { name: 'api',            kind: 'api',         design_dependent: false, parent_addon: nil },
          { name: 'stats',          kind: 'stats',       design_dependent: false, parent_addon: nil },
          { name: 'support',        kind: 'support',     design_dependent: false, parent_addon: nil },
          { name: 'preview_tools',  kind: 'previewTools',design_dependent: false, parent_addon: nil }
        ],
        App::Plugin => [
          { name: 'video_player',     token: 'sa.sh.si', addon: 'ref-Addon-video_player',   design: nil,                       component: 'ref-App::Component-app' },
          { name: 'ligthbox_classic', token: 'sa.sl.sm', addon: 'ref-Addon-lightbox',       design: 'ref-App::Design-classic', component: 'ref-App::Component-app' },
          { name: 'ligthbox_flat',    token: 'sa.sl.sm', addon: 'ref-Addon-lightbox',       design: 'ref-App::Design-flat',    component: 'ref-App::Component-app' },
          { name: 'ligthbox_light',   token: 'sa.sl.sm', addon: 'ref-Addon-lightbox',       design: 'ref-App::Design-light',   component: 'ref-App::Component-app' },
          { name: 'ligthbox_twit',    token: 'sa.sl.sm', addon: 'ref-Addon-lightbox',       design: 'ref-App::Design-twit',    component: 'ref-App::Component-app' },
          { name: 'ligthbox_html5',   token: 'sa.sl.sm', addon: 'ref-Addon-lightbox',       design: 'ref-App::Design-html5',   component: 'ref-App::Component-app' },
          { name: 'image_viewer',     token: 'sa.sn.so', addon: 'ref-Addon-image_viewer',   design: nil,                       component: 'ref-App::Component-app' },
          { name: 'logo',             token: 'sa.sh.sp', addon: 'ref-Addon-logo',           design: nil,                       component: 'ref-App::Component-app' },
          { name: 'controls_classic', token: 'sa.sh.sq', addon: 'ref-Addon-controls',       design: 'ref-App::Design-classic', component: 'ref-App::Component-app' },
          { name: 'controls_flat',    token: 'sd.sd.sr', addon: 'ref-Addon-controls',       design: 'ref-App::Design-flat',    component: 'ref-App::Component-app' },
          { name: 'controls_light',   token: 'se.se.ss', addon: 'ref-Addon-controls',       design: 'ref-App::Design-light',   component: 'ref-App::Component-app' },
          { name: 'controls_twit',    token: 'sf.sf.st', addon: 'ref-Addon-controls',       design: 'ref-App::Design-twit',    component: 'ref-App::Component-twit' },
          { name: 'controls_html5',   token: 'sg.sg.su', addon: 'ref-Addon-controls',       design: 'ref-App::Design-html5',   component: 'ref-App::Component-html5' },
          { name: 'initial_classic',  token: 'sa.sh.sv', addon: 'ref-Addon-initial',        design: 'ref-App::Design-classic', component: 'ref-App::Component-app' },
          { name: 'initial_flat',     token: 'sa.sh.sv', addon: 'ref-Addon-initial',        design: 'ref-App::Design-flat',    component: 'ref-App::Component-app' },
          { name: 'initial_light',    token: 'sa.sh.sv', addon: 'ref-Addon-initial',        design: 'ref-App::Design-light',   component: 'ref-App::Component-app' },
          { name: 'initial_twit',     token: 'sa.sh.sv', addon: 'ref-Addon-initial',        design: 'ref-App::Design-twit',    component: 'ref-App::Component-app' },
          { name: 'initial_html5',    token: 'sa.sh.sv', addon: 'ref-Addon-initial',        design: 'ref-App::Design-html5',   component: 'ref-App::Component-app' },
          { name: 'sharing_classic',  token: 'sa.sh.sz', addon: 'ref-Addon-sharing',        design: 'ref-App::Design-classic', component: 'ref-App::Component-app' },
          { name: 'sharing_twit',     token: 'sa.sh.sz', addon: 'ref-Addon-sharing',        design: 'ref-App::Design-twit',    component: 'ref-App::Component-app' },
          { name: 'sharing_html5',    token: 'sa.sh.sz', addon: 'ref-Addon-sharing',        design: 'ref-App::Design-html5',   component: 'ref-App::Component-app' },
          { name: 'preview_tools',    token: 'sj.sj.sk', addon: 'ref-Addon-preview_tools',  design: nil,                       component: 'ref-App::Component-svnet' }
        ],
        AddonPlan => [
          { name: 'standard',  price: 0,    addon: 'ref-Addon-video_player', availability: 'hidden', public_at: nil },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-lightbox',     availability: 'hidden', public_at: Time.now.utc },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-image_viewer', availability: 'hidden', required_stage: 'beta', public_at: nil },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-preview_tools',availability: 'custom', required_stage: 'beta', public_at: nil },
          { name: 'invisible', price: 0,    addon: 'ref-Addon-stats',        availability: 'hidden', public_at: Time.now.utc },
          { name: 'realtime',  price: 990,  addon: 'ref-Addon-stats',        availability: 'public', public_at: Time.now.utc },
          # { name: 'disabled',  price: 1990, addon: 'ref-Addon-stats',        availability: 'hidden', required_stage: 'beta', public_at: nil },
          { name: 'sublime',   price: 0,    addon: 'ref-Addon-logo',         availability: 'public', public_at: Time.now.utc },
          { name: 'disabled',  price: 990,  addon: 'ref-Addon-logo',         availability: 'public', public_at: Time.now.utc },
          { name: 'custom',    price: 1990, addon: 'ref-Addon-logo',         availability: 'public', required_stage: 'beta', public_at: nil },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-controls',     availability: 'hidden', required_stage: 'beta', public_at: nil },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-initial',      availability: 'hidden', required_stage: 'beta', public_at: nil },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-sharing',      availability: 'public', required_stage: 'beta', public_at: nil },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-api',          availability: 'hidden', public_at: Time.now.utc },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-support',      availability: 'public', public_at: Time.now.utc },
          { name: 'vip',       price: 9990, addon: 'ref-Addon-support',      availability: 'public', public_at: Time.now.utc }
        ],
        App::SettingsTemplate => [
          { addon_plan: 'ref-AddonPlan-video_player-standard', plugin: 'ref-App::Plugin-video_player',
            template: {
              enable_volume: {
                type: 'boolean',
                values: [true, false],
                default: true
              },
              enable_fullmode: {
                type: 'boolean',
                values: [true, false],
                default: true
              },
              force_fullwindow: {
                type: 'boolean',
                values: [true, false],
                default: false,
              },
              on_end: {
                type: 'string',
                values: ['nothing', 'replay', 'stop'],
                default: 'nothing'
              }
            }
          },
          { addon_plan: 'ref-AddonPlan-controls-standard',     plugin: 'ref-App::Plugin-controls_classic', template: controls_template },
          { addon_plan: 'ref-AddonPlan-controls-standard',     plugin: 'ref-App::Plugin-controls_flat',    template: controls_template },
          { addon_plan: 'ref-AddonPlan-controls-standard',     plugin: 'ref-App::Plugin-controls_light',   template: controls_template },
          { addon_plan: 'ref-AddonPlan-controls-standard',     plugin: 'ref-App::Plugin-controls_twit',    template: controls_template },
          { addon_plan: 'ref-AddonPlan-controls-standard',     plugin: 'ref-App::Plugin-controls_html5',   template: controls_template },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox_classic', template: lightbox_template },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox_flat',    template: lightbox_template },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox_light',   template: lightbox_template },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox_twit',    template: lightbox_template },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox_html5',   template: lightbox_template },
          # { addon_plan: 'ref-AddonPlan-image_viewer-standard', plugin: 'ref-App::Plugin-image_viewer' },
          { addon_plan: 'ref-AddonPlan-stats-invisible',       plugin: nil,
            template: {
              enable: {
                type: 'boolean',
                values: [true],
                default: true
              },
              realtime: {
                type: 'boolean',
                values: [false],
                default: false
              }
            }
          },
          { addon_plan: 'ref-AddonPlan-stats-realtime', plugin: nil,
            template: {
              enable: {
                type: 'boolean',
                values: [false],
                default: false
              },
              realtime: {
                type: 'boolean',
                values: [true],
                default: true
              }
            }
          },
          # { addon_plan: 'ref-AddonPlan-stats-disabled', plugin: nil, editable: false,
          #   template: {
          #     enabled: {
          #       type: 'boolean',
          #       values: [true, false],
          #       default: false
          #     },
          #     realtime: {
          #       type: 'boolean',
          #       values: [true, false],
          #       default: false
          #     }
          #   }
          # },
          { addon_plan: 'ref-AddonPlan-logo-sublime', plugin: 'ref-App::Plugin-logo',
            template: {
              enable: {
                type: 'boolean',
                values: [true],
                default: true
              },
              type: {
                type: 'string',
                values: ['sv'],
                default: 'sv'
              },
              visibility: {
                type: 'string',
                values: ['autohide', 'visible'],
                default: 'autohide'
              },
              position: {
                type: 'string',
                values: ['bottomRight'],
                default: 'bottomRight'
              },
              image_url: {
                type: 'image',
                default: ''
              },
              link_url: {
                type: 'url'
              }
            }
          },
          { addon_plan: 'ref-AddonPlan-logo-disabled', plugin: 'ref-App::Plugin-logo',
            template: {
              enable: {
                type: 'boolean',
                values: [true, false],
                default: false
              },
              type: {
                type: 'string',
                values: ['sv'],
                default: 'sv'
              },
              visibility: {
                type: 'string',
                values: ['autohide', 'visible'],
                default: 'autohide'
              },
              position: {
                type: 'string',
                values: ['bottomRight'],
                default: 'bottomRight'
              },
              image_url: {
                type: 'image',
                values: [''],
                default: ''
              },
              link_url: {
                type: 'url'
              }
            }
          },
          { addon_plan: 'ref-AddonPlan-logo-custom', plugin: 'ref-App::Plugin-logo',
            template: {
              enable: {
                type: 'boolean',
                values: [true, false],
                default: false
              },
              type: {
                type: 'string',
                values: ['sv', 'custom'],
                default: 'sv'
              },
              visibility: {
                type: 'string',
                values: ['autohide', 'visible'],
                default: 'autohide'
              },
              position: {
                type: 'string',
                values: ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'],
                default: 'bottomRight'
              },
              image_url: {
                type: 'image'
              },
              link_url: {
                type: 'url'
              }
            }
          },
          { addon_plan: 'ref-AddonPlan-initial-standard', plugin: 'ref-App::Plugin-initial_classic', template: initial_template },
          { addon_plan: 'ref-AddonPlan-initial-standard', plugin: 'ref-App::Plugin-initial_flat', template: initial_template },
          { addon_plan: 'ref-AddonPlan-initial-standard', plugin: 'ref-App::Plugin-initial_light', template: initial_template },
          { addon_plan: 'ref-AddonPlan-initial-standard', plugin: 'ref-App::Plugin-initial_twit', template: initial_template },
          { addon_plan: 'ref-AddonPlan-initial-standard', plugin: 'ref-App::Plugin-initial_html5', template: initial_template },
          { addon_plan: 'ref-AddonPlan-sharing-standard', plugin: 'ref-App::Plugin-sharing_classic', template: sharing_template },
          { addon_plan: 'ref-AddonPlan-sharing-standard', plugin: 'ref-App::Plugin-sharing_twit', template: sharing_template },
          { addon_plan: 'ref-AddonPlan-sharing-standard', plugin: 'ref-App::Plugin-sharing_html5', template: sharing_template }
        ]
      }
      if Rails.env.development?
        seeds[App::ComponentVersion] = [
          # { component: 'ref-App::Component-app', version: '2.0.0-alpha', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          # { component: 'ref-App::Component-app', version: '2.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          # { component: 'ref-App::Component-app', version: '1.1.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-app', version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          # { component: 'ref-App::Component-twit', version: '2.0.0-alpha', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          # { component: 'ref-App::Component-twit', version: '2.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          # { component: 'ref-App::Component-twit', version: '1.1.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-twit', version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          # { component: 'ref-App::Component-html5', version: '2.0.0-alpha', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          # { component: 'ref-App::Component-html5', version: '2.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          # { component: 'ref-App::Component-html5', version: '1.1.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-html5', version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) }
        ]
      end

      seeds.each do |klass, new_record|
        new_record.each do |attributes|
          attributes = attributes.inject({}) do |h, (k, v)|
            if v =~ /\Aref-/
              parts = v.split('-')
              parent_klass = parts[1].constantize
              parent_record = if parent_klass == AddonPlan
                parent_klass.get(parts[2], parts[3])
              else
                parent_klass.find_by_name(parts[2])
              end
              h[k] = parent_record
            else
              h[k] = v
            end
            h
          end
          klass.create(attributes, as: :admin)
        end
        puts "\t- #{klass.count} #{klass.to_s} created;" unless Rails.env.test?
      end
    end

    def mail_templates(count = 5)
      empty_tables(MailTemplate)
      count.times do |i|
        MailTemplate.create(
          title: Faker::Lorem.sentence(1),
          subject: Faker::Lorem.sentence(1),
          body: Faker::Lorem.paragraphs(3).join("\n\n")
        )
      end
      puts "#{count} random mail templates created!"
    end

    def admins
      empty_tables(Admin)
      disable_perform_deliveries do
        puts "Creating admins..."
        BASE_USERS.each do |admin_info|
          Admin.create(email: admin_info[1], password: "123456", roles: ['god'])
          puts "Admin #{admin_info[1]}:123456"
        end
      end
    end

    def enthusiasts(user_id = nil)
      empty_tables(EnthusiastSite, Enthusiast)
      disable_perform_deliveries do
        (user_id ? [user_id] : 0.upto(BASE_USERS.count - 1)).each do |i|
          enthusiast = Enthusiast.create(email: BASE_USERS[i][1], interested_in_beta: true)
          enthusiast.confirmed_at = Time.now
          enthusiast.save!
          print "Enthusiast #{BASE_USERS[0]} created!\n"
        end
      end
    end

    def users(user_id = nil)
      empty_tables("invoices_transactions", InvoiceItem, Invoice, Transaction, Site, User)
      created_at_array = (Date.new(2011,1,1)..100.days.ago.to_date).to_a
      disable_perform_deliveries do
        (user_id ? [user_id.to_i] : 0.upto(BASE_USERS.count - 1)).each do |i|
          user = User.new(
            email: BASE_USERS[i][1],
            password: "123456",
            name: BASE_USERS[i][0],
            postal_code: Faker::Address.zip_code,
            country: COUNTRIES.sample,
            billing_name: BASE_USERS[i][0],
            billing_address_1: Faker::Address.street_address,
            billing_address_2: Faker::Address.secondary_address,
            billing_postal_code: Faker::Address.zip_code,
            billing_city: Faker::Address.city,
            billing_region: Faker::Address.uk_county,
            billing_country: COUNTRIES.sample,
            use_personal: true,
            terms_and_conditions: "1",
            cc_brand: 'visa',
            cc_full_name: BASE_USERS[i][0],
            cc_number: "4111111111111111",
            cc_verification_value: "111",
            cc_expiration_month: 12,
            cc_expiration_year: 2.years.from_now.year
          )
          user.created_at   = created_at_array.sample
          user.confirmed_at = user.created_at
          user.save!
          puts "User #{BASE_USERS[i][1]}:123456 created!"
        end

        use_personal = false
        use_company  = false
        use_clients  = false
        case rand
        when 0..0.4
          use_personal = true
        when 0.4..0.7
          use_company = true
        when 0.7..1
          use_clients = true
        end
      end
    end

    def sites
      empty_tables(Site)
      delete_all_files_in_public('uploads/licenses')
      delete_all_files_in_public('uploads/loaders')
      Populate.users if User.all.empty?
      Populate.plans if Plan.all.empty?

      subdomains = %w[www blog my git sv ji geek yin yang chi cho chu foo bar rem]

      User.all.each do |user|
        BASE_SITES.each do |hostname|
          created_at = rand(24).months.ago
          Timecop.travel(created_at)
          if rand >= 0.5
            site = user.sites.create({ hostname: hostname, plan_id: Plan.where(name: %w[plus premium].sample, cycle: 'month').first.id }, without_protection: true)
            service = Service::Site.new(site)
            service.migrate_plan_to_addons!(AddonPlan.free_addon_plans, AddonPlan.free_addon_plans(reject: %w[logo stats support]))
            service.send :create_default_kit!
          else
            site = user.sites.build(hostname: hostname)
            Service::Site.new(site).create
            if rand >= 0.4
              Timecop.return
              Timecop.travel(created_at + 30.days)
              Service::Trial.activate_billable_items_out_of_trial_for_site!(site.id)
            end
          end
          Timecop.return
        end
      end

      puts "#{BASE_SITES.size} beautiful sites created for each user!"
    end

    def invoices(user_id = nil)
      empty_tables("invoices_transactions", InvoiceItem, Invoice, Transaction)
      users = user_id ? [User.find(user_id)] : User.all
      users.each do |user|
        user.sites.active.each do |site|
          timestamp = site.created_at
          while timestamp < Time.now.utc do
            timestamp += 1.month
            Timecop.travel(timestamp.end_of_month) do
              service = Service::Invoice.build_for_month(Time.now.utc, site.id).tap { |s| s.save }
              service.invoice.succeed if service.invoice.persisted?
            end
          end
        end
      end
    end

    def site_usages
      empty_tables(SiteUsage)
      end_date = Date.today
      player_hits_total = 0
      Site.active.each do |site|
        start_date = (site.plan_cycle_started_at? ? site.plan_month_cycle_started_at : (1.month - 1.day).ago.midnight).to_date
        plan_video_views = 200_000 # site.in_sponsored_plan? || site.in_free_plan? ? Plan.standard_plans.all.sample.video_views : site.plan.video_views
        p = (case rand(4)
        when 0
          plan_video_views/30.0 - (plan_video_views/30.0/4)
        when 1
          plan_video_views/30.0 - (plan_video_views/30.0/8)
        when 2
          plan_video_views/30.0 + (plan_video_views/30.0/4)
        when 3
          plan_video_views/30.0 + (plan_video_views/30.0/8)
        end).to_i

        (start_date..end_date).each do |day|
          Timecop.travel(day) do
            loader_hits                = p * rand(100)
            main_player_hits           = (p * rand).to_i
            main_player_hits_cached    = (p * rand).to_i
            extra_player_hits          = (p * rand).to_i
            extra_player_hits_cached   = (p * rand).to_i
            dev_player_hits            = rand(100)
            dev_player_hits_cached     = (dev_player_hits * rand).to_i
            invalid_player_hits        = rand(500)
            invalid_player_hits_cached = (invalid_player_hits * rand).to_i
            player_hits = main_player_hits + main_player_hits_cached + extra_player_hits + extra_player_hits_cached + dev_player_hits + dev_player_hits_cached + invalid_player_hits + invalid_player_hits_cached
            requests_s3 = player_hits - (main_player_hits_cached + extra_player_hits_cached + dev_player_hits_cached + invalid_player_hits_cached)

            site_usage = SiteUsage.new(
              day: day.to_time.utc.midnight,
              site_id: site.id,
              loader_hits: loader_hits,
              main_player_hits: main_player_hits,
              main_player_hits_cached: main_player_hits_cached,
              extra_player_hits: extra_player_hits,
              extra_player_hits_cached: extra_player_hits_cached,
              dev_player_hits: dev_player_hits,
              dev_player_hits_cached: dev_player_hits_cached,
              invalid_player_hits: invalid_player_hits,
              invalid_player_hits_cached: invalid_player_hits_cached,
              player_hits: player_hits,
              flash_hits: (player_hits * rand / 3).to_i,
              requests_s3: requests_s3,
              traffic_s3: requests_s3 * 150000, # 150 KB
              traffic_voxcast: player_hits * 150000
            )
            site_usage.save!
            player_hits_total += player_hits
          end
        end
      end
      puts "#{player_hits_total} video-page views total!"
    end

    def create_stats(site_token = nil)
      sites = site_token ? [Site.find_by_token(site_token)] : Site.all
      sites.each do |site|
        VideoTag.where(site_id: site).delete_all
        Stat::Site::Day.where(t: site.token).delete_all
        Stat::Site::Hour.where(t: site.token).delete_all
        Stat::Site::Minute.where(t: site.token).delete_all
        Stat::Site::Second.where(t: site.token).delete_all
        Stat::Video::Day.where(st: site.token).delete_all
        Stat::Video::Hour.where(st: site.token).delete_all
        Stat::Video::Minute.where(st: site.token).delete_all
        Stat::Video::Second.where(st: site.token).delete_all
        videos_count = 20
        # Video Tags
        videos_count.times do |video_i|
          VideoTag.create(site: site, uid: "video#{video_i}",
            uid_origin: "s",
            name: "Video #{video_i} long name test truncate",
            name_origin: "s",
            current_sources: ["83cb4c27","83cb4c57","af355ec8", "af355ec9"],
            poster_url: "http#{'s' if video_i.even?}://d1p69vb2iuddhr.cloudfront.net/assets/www/demo/midnight_sun_800-4f8c545242632c5352bc9da1addabcf5.jpg",
            size: "544x306",
            sources: {
              "83cb4c27" => { url: "http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.mp4", quality: "base", family: "mp4" },
              "83cb4c57" => { url: "http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.mp4", quality: "hd", family: "mp4" },
              "af355ec8" => { url: "http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.webm", quality: "base", family: "webm" },
              "af355ec9" => { url: "http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.webm", quality: "hd", family: "webm" },
            }
          )
        end

        # Days
        puts "Generating 95 days of stats for #{site.hostname}"
        95.times.each do |i|
          time = i.days.ago.change(hour: 0, min: 0, sec: 0, usec: 0).to_time
          Stat::Site::Day.collection
            .find(t: site.token, d: time)
            .update({ :$inc => random_site_stats_inc(24 * 60 * 60) }, upsert: true)
          videos_count.times do |video_i|
            Stat::Video::Day.collection
              .find(st: site.token, u: "video#{video_i}", d: time)
              .update({ :$inc => random_video_stats_inc(24 * 60 * 60) }, upsert: true)
          end
        end

        # Hours
        puts "Generating 25 hours of stats for #{site.hostname}"
        25.times.each do |i|
          time = i.hours.ago.change(min: 0, sec: 0, usec: 0).to_time
          Stat::Site::Hour.collection
            .find(t: site.token, d: time)
            .update({ :$inc => random_site_stats_inc(60 * 60) }, upsert: true)
          videos_count.times do |video_i|
            Stat::Video::Hour.collection
            .find(st: site.token, u: "video#{video_i}", d: time)
            .update({ :$inc => random_video_stats_inc(60 * 60) }, upsert: true)
          end
        end

        # Minutes
        puts "Generating 60 minutes of stats for #{site.hostname}"
        60.times.each do |i|
          time = i.minutes.ago.change(sec: 0, usec: 0).to_time
          Stat::Site::Minute.collection
            .find(t: site.token, d: time)
            .update({ :$inc => random_site_stats_inc(60) }, upsert: true)
          videos_count.times do |video_i|
            Stat::Video::Minute.collection
              .find(st: site.token, u: "video#{video_i}", d: time)
              .update({ :$inc => random_video_stats_inc(60) }, upsert: true)
          end
        end

        # Seconds
        puts "Generating 60 seconds of stats for #{site.hostname}"
        60.times.each do |i|
          time = i.seconds.ago.change(usec: 0).to_time
          Stat::Site::Second.collection
            .find(t: site.token, d: time)
            .update({ :$inc => random_site_stats_inc(1) }, upsert: true)
          videos_count.times do |video_i|
            Stat::Video::Second.collection
              .find(st: site.token, u: "video#{video_i}", d: time)
              .update({ :$inc => random_video_stats_inc(1) }, upsert: true)
          end
        end
        site.update_last_30_days_video_views_counters
      end
      puts "Fake site(s)/video(s) stats generated"
    end

    def site_stats(user_id = nil)
      empty_tables(Stat::Site::Day, Stat::Site::Hour, Stat::Site::Minute, Stat::Site::Second)
      users = user_id ? [User.find(user_id)] : User.all
      users.each do |user|
        user.sites.each do |site|
          # Days
          95.times.each do |i|
            stats = random_site_stats_inc(24 * 60 * 60)
            Stat::Site::Day.collection
              .find(t: site.token, d: i.days.ago.change(hour: 0, min: 0, sec: 0, usec: 0).to_time)
              .update({ :$inc => stats }, upsert: true)
            SiteUsage.create(
              day: i.days.ago.to_time.utc.midnight,
              site_id: site.id,
              loader_hits: 0,
              main_player_hits: stats.slice('pv.m', 'pv.em').values.sum,
              main_player_hits_cached: 0,
              extra_player_hits: stats['pv.e'],
              extra_player_hits_cached: 0,
              dev_player_hits: stats['pv.d'],
              dev_player_hits_cached: 0,
              invalid_player_hits: stats['pv.i'],
              invalid_player_hits_cached: 0,
              player_hits: stats.slice('pv.m', 'pv.e', 'pv.em', 'pv.d', 'pv.i').values.sum,
              flash_hits: stats.slice('md.f.d', 'md.f.m', 'md.f.t').values.sum,
              requests_s3: 0,
              traffic_s3: 0,
              traffic_voxcast: 0
            )
          end
          # Hours
          25.times.each do |i|
            Stat::Site::Hour.collection
              .find(t: site.token, d: i.hours.ago.change(min: 0, sec: 0, usec: 0).to_time)
              .update({ :$inc => random_site_stats_inc(60 * 60) }, upsert: true)
          end
          # Minutes
          60.times.each do |i|
            Stat::Site::Minute.collection
              .find(t: site.token, d: i.minutes.ago.change(sec: 0, usec: 0).to_time)
              .update({ :$inc => random_site_stats_inc(60) }, upsert: true)
          end
          # seconds
          60.times.each do |i|
            Stat::Site::Second.collection
              .find(t: site.token, d: i.seconds.ago.change(usec: 0).to_time)
              .update({ :$inc => random_site_stats_inc(1) }, upsert: true)
          end
          Service::Usage.new(site).update_last_30_days_video_views_counters
        end
      end
      puts "Fake site(s) stats generated"
    end

    def users_stats
      empty_tables(Stats::UsersStat)
      day = 2.years.ago.midnight
      hash = { fr: 0, pa: 0, su: 0, ar: 0 }

      while day <= Time.now.utc.midnight
        hash[:d]   = day
        hash[:fr] += rand(100)
        hash[:pa] += rand(25)
        hash[:su] += rand(2)
        hash[:ar] += rand(4)

        Stats::UsersStat.create(hash)

        day += 1.day
      end

      puts "#{Stats::UsersStat.count} fake users stats generated!"
    end

    def sites_stats
      empty_tables(Stats::SitesStat)
      day = 2.years.ago.midnight
      hash = { fr: { free: 0 }, pa: { plus: { m: 0, y: 0 }, premium: { m: 0, y: 0 }, addons: 0 }, su: 0, ar: 0 }

      while day <= Time.now.utc.midnight
        hash[:d]   = day
        hash[:fr][:free] += rand(50)

        if day >= Time.utc(2012, 10, 23)
          hash[:pa][:addons]      += rand(12)
        else
          hash[:pa][:plus][:m]    += rand(7)
          hash[:pa][:plus][:y]    += rand(3)
          hash[:pa][:premium][:m] += rand(4)
          hash[:pa][:premium][:y] += rand(2)
        end
        hash[:su] += rand(3)
        hash[:ar] += rand(6)

        Stats::SitesStat.create(hash)

        day += 1.day
      end

      puts "#{Stats::SitesStat.count} fake sites stats generated!"
    end

    def sales_stats
      empty_tables(Stats::SalesStat)
      Stats::SalesStat.create_stats

      puts "#{Stats::SalesStat.count} fake sales stats generated!"
    end

    def recurring_site_stats_update(user_id)
      empty_tables(Stat::Site::Day, Stat::Site::Hour, Stat::Site::Minute, Stat::Site::Second)
      sites = User.find(user_id).sites
      puts "Begin recurring fake site(s) stats generation (each minute)"
      Thread.new do
        loop do
          second = Time.now.utc.change(usec: 0).to_time
          sites.each do |site|
            inc = random_site_stats_inc(1)
            Stat::Site::Second.collection
              .find(t: site.token, d: second)
              .update({ :$inc => inc }, upsert: true)
          end
          # puts "Site(s) stats seconds updated at #{second}"
          sleep 1
        end
      end
      Thread.new do
        loop do
          now = Time.now.utc
          if now.change(usec: 0) == now.change(sec: 0, usec: 0)
            sites.each do |site|
              inc = random_site_stats_inc(60)
              Stat::Site::Minute.collection
                .find(t: site.token, d: (now - 1.minute).change(sec: 0, usec: 0).to_time)
                .update({ :$inc => inc }, upsert: true)
              Stat::Site::Hour.collection
                .find(t: site.token, d: (now - 1.minute).change(min: 0, sec: 0, usec: 0).to_time)
                .update({ :$inc => inc }, upsert: true)
              Stat::Site::Day.collection
                .find(t: site.token, d: (now - 1.minute).change(hour: 0, min: 0, sec: 0, usec: 0).to_time)
                .update({ :$inc => inc }, upsert: true)
            end

            json = {}
            json[:h] = true if now.change(sec: 0, usec: 0) == now.change(min: 0, sec: 0, usec: 0)
            json[:d] = true if now.change(min: 0, sec: 0, usec: 0) == now.change(hour: 0, min: 0, sec: 0, usec: 0)
            Pusher.trigger('stats', 'tick', json)

            puts "Site(s) stats updated at #{now.change(sec: 0, usec: 0)}"
            sleep 50
          end
          sleep 0.9
        end
      end
      EM.run do
        EM.add_periodic_timer(1) do
          EM.defer do
            second = Time.now.change(usec: 0).to_time
            site = sites.order(:hostname).first()
            json = { "pv" => 1, "bp" => { "saf-osx" => 1 } }
            Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
            json = { "md" => { "f" => { "d" => 1 }, "h" => { "d" => 1 } } }
            Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
            json = { "vv" => 1 }
            Pusher.trigger_async("private-#{site.token}", 'stats', json.merge('id' => second.to_i))
          end
        end
      end
    end

    def recurring_stats_update(site_token)
      site         = Site.find_by_token(site_token)
      last_second  = 0
      videos_count = 20
      EM.run do
        EM.add_periodic_timer(0.001) do
          second = Time.now.change(usec: 0).to_time
          if last_second != second.to_i
            sleep rand(1)
            last_second = second.to_i
            EM.defer do
              videos_count.times do |video_i|
                if rand(10) >= 8
                  hits = rand(10) #second.to_i%10
                  Stat::Site::Second.collection
                    .find(t: site.token, d: second)
                    .udate({ :$inc => { 'vv.m' => hits } }, upsert: true)
                  Stat::Video::Second.collection
                    .find(st: site.token, d:  "video#{video_i}", s: second)
                    .update({ :$inc => { 'vv.m' => hits } }, upsert: true)
                  json = {
                    site: { id: second.to_i, vv: hits },
                    videos: [
                      { id: second.to_i, u: "video#{video_i}", n: "Video #{video_i}", vv: hits }
                    ]
                  }
                  Pusher.trigger_async("private-#{site.token}", 'stats', json)
                end
              end
              puts "Stats updated at #{second}"
            end
          end
        end
      end
    end

    def video_tags(site_token)
      empty_tables(VideoTag)
      site = Site.find_by_token!(site_token)
      (100 + rand(200)).times do
        time = rand(3000).hours.ago
        VideoTag.create(
          site: site,
          uid: generate_unique_token,
          uid_origin: %w[a s].sample,
          name: Faker::Product.product,
          name_origin: %w[a s].sample,
          poster_url: 'http://media.jilion.com/vcg/ms_800.jpg',
          size: '400x320',
          current_sources: %w[5ABAC533 2ABFEFDA 97230509 4E855AFF],
          sources: {
            '5ABAC533' => { url: 'http://media.jilion.com/vcg/ms_360p.mp4',  quality: 'base', family: 'mp4' },
            '2ABFEFDA' => { url: 'http://media.jilion.com/vcg/ms_720p.mp4',  quality: 'hd',   family: 'mp4' },
            '97230509' => { url: 'http://media.jilion.com/vcg/ms_360p.webm', quality: 'base', family: 'webm' },
            '4E855AFF' => { url: 'http://media.jilion.com/vcg/ms_720p.webm', quality: 'hd',   family: 'webm' }
          },
          duration: (15 * 1000) + rand(2 * 60 * 60 * 1000),
          created_at: time,
          updated_at: time
        )
      end
      site.update_last_30_days_video_tags_counters
    end

    def send_all_emails(user_id)
      disable_perform_deliveries do
        user         = User.find(user_id)
        trial_site   = user.sites.in_trial.last
        site         = user.sites.joins(:invoices).in_paid_plan.group { sites.id }.having { { invoices => (count(id) > 0) } }.last || user.sites.last
        invoice      = site.invoices.last || Service::Invoice.build(site: site).invoice
        transaction  = invoice.transactions.last || Transaction.create(invoices: [invoice])
        stats_export = StatsExport.create(st: site.token, from: 30.days.ago.midnight.to_i, to: 1.days.ago.midnight.to_i, file: File.new(Rails.root.join('spec/fixtures', 'stats_export.csv')))

        DeviseMailer.confirmation_instructions(user).deliver!
        DeviseMailer.reset_password_instructions(user).deliver!

        UserMailer.welcome(user.id).deliver!
        UserMailer.account_suspended(user.id).deliver!
        UserMailer.account_unsuspended(user.id).deliver!
        UserMailer.account_archived(user.id).deliver!

        BillingMailer.trial_has_started(trial_site.id).deliver!
        BillingMailer.trial_will_expire(trial_site.id).deliver!
        BillingMailer.trial_has_expired(trial_site.id).deliver!
        BillingMailer.yearly_plan_will_be_renewed(site.id).deliver!

        BillingMailer.credit_card_will_expire(user.id).deliver!

        BillingMailer.transaction_succeeded(transaction.id).deliver!
        BillingMailer.transaction_failed(transaction.id).deliver!

        BillingMailer.too_many_charging_attempts(invoice.id).deliver!

        StatsExportMailer.export_ready(stats_export).deliver!

        MailMailer.send_mail_with_template(user.id, MailTemplate.last.id).deliver!

        UsageMonitoringMailer.plan_overused(site.id).deliver!
        UsageMonitoringMailer.plan_upgrade_required(site.id).deliver!
      end
    end

    def delete_all_files_in_public(*paths)
      paths.each do |path|
        if path.gsub('.', '') =~ /\w+/ # don't remove all files and directories in /public ! ;)
          print "Deleting all files and directories in /public/#{path}\n" if Rails.env.development?
          timed do
            Dir["#{Rails.public_path}/#{path}/**/*"].each do |filename|
              File.delete(filename) if File.file?(filename)
            end
            Dir["#{Rails.public_path}/#{path}/**/*"].each do |filename|
              Dir.delete(filename) if File.directory?(filename)
            end
          end
        end
      end
    end

    def empty_tables(*tables)
      print "Deleting the content of #{tables.join(', ')}.. => " if Rails.env.development?
      tables.each do |table|
        if table.is_a?(Class)
          table.delete_all
        else
          Site.connection.delete("DELETE FROM #{table} WHERE 1=1")
        end
      end
      puts "#{tables.join(', ')} empty!" if Rails.env.development?
    end

    private

    def disable_perform_deliveries(&block)
      if block_given?
        original_perform_deliveries = ActionMailer::Base.perform_deliveries
        # Disabling perform_deliveries (avoid to spam fakes email adresses)
        ActionMailer::Base.perform_deliveries = false

        yield

        # Switch back to the original perform_deliveries
        ActionMailer::Base.perform_deliveries = original_perform_deliveries
      else
        print "\n\nYou must pass a block to this method!\n\n"
      end
    end

    def random_site_stats_inc(i, force = nil)
      {
        # field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 3 }
        "pv.m"  => force || (i * rand).round,
        "pv.e"  => force || (i * rand / 2).round,
        "pv.em" => force || (i * rand / 2).round,
        "pv.d"  => force || (i * rand / 2).round,
        "pv.i"  => force || (i * rand / 2).round,
        # field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 3 }
        "vv.m"  => force || (i * rand / 2).round,
        "vv.e"  => force || (i * rand / 4).round,
        "vv.em" => force || (i * rand / 4).round,
        "vv.d"  => force || (i * rand / 6).round,
        "vv.i"  => force || (i * rand / 6).round,
        # field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1, t (tablet) => 1 }, f (flash) => ... }
        "md.h.d" => i * rand(12),
        "md.h.m" => i * rand(5),
        "md.h.t" => i * rand(3),
        "md.f.d" => i * rand(6),
        "md.f.m" => 0, #i * rand(2),
        "md.f.t" => 0, #i * rand(2),
        # field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}
        "bp.iex-win" => i * rand(35), # 35% in total
        "bp.fir-win" => i * rand(18), # 26% in total
        "bp.fir-osx" => i * rand(8),
        "bp.chr-win" => i * rand(11), # 21% in total
        "bp.chr-osx" => i * rand(10),
        "bp.saf-win" => i * rand(1).round, # 6% in total
        "bp.saf-osx" => i * rand(5),
        "bp.saf-ipo" => i * rand(1),
        "bp.saf-iph" => i * rand(2),
        "bp.saf-ipa" => i * rand(2),
        "bp.and-and" => i * rand(6)
      }
    end

    def random_video_stats_inc(i, force = nil)
      {
        # field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 3 }
        "vl.m"  => force || (i * rand(20)).round,
        "vl.e"  => force || (i * rand(4)).round,
        "vl.em" => force || (i * rand(2)).round,
        "vl.d"  => force || (i * rand(2)).round,
        "vl.i"  => force || (i * rand(2)).round,
        # field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 3 }
        "vv.m"  => force || (i * rand(10)).round,
        "vv.e"  => force || (i * rand(3)).round,
        "vv.em" => force || (i * rand(3)).round,
        "vv.d"  => force || (i * rand(2)).round,
        "vv.i"  => force || (i * rand(2)).round,
        # field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1, t (tablet) => 1 }, f (flash) => ... }
        "md.h.d" => i * rand(12),
        "md.h.m" => i * rand(5),
        "md.h.t" => i * rand(3),
        "md.f.d" => i * rand(6),
        "md.f.m" => 0, #i * rand(2),
        "md.f.t" => 0, #i * rand(2),
        # field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}
        "bp.iex-win" => i * rand(35), # 35% in total
        "bp.fir-win" => i * rand(18), # 26% in total
        "bp.fir-osx" => i * rand(8),
        "bp.chr-win" => i * rand(11), # 21% in total
        "bp.chr-osx" => i * rand(10),
        "bp.saf-win" => i * rand(1).round, # 6% in total
        "bp.saf-osx" => i * rand(5),
        "bp.saf-ipo" => i * rand(1),
        "bp.saf-iph" => i * rand(2),
        "bp.saf-ipa" => i * rand(2),
        "bp.and-and" => i * rand(6)
      }
    end

    def generate_unique_token
      options = { length: 8, chars: ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a }
      Array.new(options[:length]) { options[:chars].to_a[rand(options[:chars].to_a.size)] }.join
    end
  end


end
