# coding: utf-8
require 'ffaker' if Rails.env.development?
require_dependency 'service/site'
require_dependency 'service/usage'
require_dependency 'service/invoice'

module Populate

  class << self

    BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]
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

      seeds = {
        App::Component => [
          { name: 'app', token: 'e' },
          { name: 'subtitles', token: 'bA' }
        ],
        App::ComponentVersion => [
          { component: 'ref-App::Component-app', version: '2.0.0-alpha', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-app', version: '2.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-app', version: '1.1.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-app', version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-subtitles', version: '2.0.0-alpha', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-subtitles', version: '2.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-subtitles', version: '1.1.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) },
          { component: 'ref-App::Component-subtitles', version: '1.0.0', zip: File.new(Rails.root.join('spec/fixtures/app/e.zip')) }
        ],
        App::Design => [
          { name: 'classic', skin_token: 'classic', price: 0, availability: 'public', component: 'ref-App::Component-app' },
          { name: 'light',   skin_token: 'light',   price: 0, availability: 'public', component: 'ref-App::Component-app' },
          { name: 'flat',    skin_token: 'flat',    price: 0, availability: 'public', component: 'ref-App::Component-app' },
          { name: 'twit',    skin_token: 'twit',    price: 0, availability: 'custom', component: 'ref-App::Component-app' }
        ],
        Addon => [
          { name: 'video_player', design_dependent: false, context: ['videoPlayer'] },
          { name: 'logo',         design_dependent: false, context: ['videoPlayer', 'badge'] },
          { name: 'stats',        design_dependent: false, context: ['videoPlayer', 'stats'] },
          { name: 'lightbox',     design_dependent: true,  context: ['lightbox'] },
          { name: 'api',          design_dependent: false },
          { name: 'support',      design_dependent: false }
        ],
        AddonPlan => [
          { name: 'standard',  price: 0,    addon: 'ref-Addon-video_player', availability: 'hidden' },
          { name: 'sublime',   price: 0,    addon: 'ref-Addon-logo',         availability: 'public' },
          { name: 'disabled',  price: 995,  addon: 'ref-Addon-logo',         availability: 'public' },
          { name: 'custom',    price: 1995, addon: 'ref-Addon-logo',         availability: 'public', works_with_stable_app: false },
          { name: 'invisible', price: 0,    addon: 'ref-Addon-stats',        availability: 'hidden' },
          { name: 'realtime',  price: 995,  addon: 'ref-Addon-stats',        availability: 'public' },
          { name: 'disabled',  price: 1995, addon: 'ref-Addon-stats',        availability: 'hidden', works_with_stable_app: false },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-lightbox',     availability: 'public' },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-api',          availability: 'public' },
          { name: 'standard',  price: 0,    addon: 'ref-Addon-support',      availability: 'public' },
          { name: 'vip',      price: 9995,  addon: 'ref-Addon-support',      availability: 'public' }
        ],
        App::Plugin => [
          { token: 'videoPlayer',      addon: 'ref-Addon-video_player', design: nil,                       component: 'ref-App::Component-app' },
          { token: 'logo',             addon: 'ref-Addon-logo',         design: nil,                       component: 'ref-App::Component-app' },
          { token: 'stats',            addon: 'ref-Addon-stats',        design: nil,                       component: 'ref-App::Component-app' },
          { token: 'ligthbox.Classic', addon: 'ref-Addon-lightbox',     design: 'ref-App::Design-classic', component: 'ref-App::Component-app' },
          { token: 'ligthbox.Light',   addon: 'ref-Addon-lightbox',     design: 'ref-App::Design-light',   component: 'ref-App::Component-app' },
          { token: 'ligthbox.Flat',    addon: 'ref-Addon-lightbox',     design: 'ref-App::Design-flat',    component: 'ref-App::Component-app' },
          { token: 'ligthbox.Twit',    addon: 'ref-Addon-lightbox',     design: 'ref-App::Design-twit',    component: 'ref-App::Component-app' },
          { token: 'api',              addon: 'ref-Addon-api',          design: nil,                       component: 'ref-App::Component-app' }
          # { token: 'support',          addon: 'ref-Addon-support',      design: nil,                       component: 'ref-App::Component-app' }
        ],
        App::SettingsTemplate => [
          { addon_plan: 'ref-AddonPlan-video_player-standard', plugin: 'ref-App::Plugin-videoPlayer' },
          { addon_plan: 'ref-AddonPlan-logo-sublime',          plugin: 'ref-App::Plugin-logo' },
          { addon_plan: 'ref-AddonPlan-logo-disabled',         plugin: 'ref-App::Plugin-logo' },
          { addon_plan: 'ref-AddonPlan-logo-custom',           plugin: 'ref-App::Plugin-logo' },
          { addon_plan: 'ref-AddonPlan-stats-invisible',       plugin: 'ref-App::Plugin-stats' },
          { addon_plan: 'ref-AddonPlan-stats-realtime',        plugin: 'ref-App::Plugin-stats' },
          { addon_plan: 'ref-AddonPlan-stats-disabled',        plugin: 'ref-App::Plugin-stats' },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox.Classic' },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox.Light' },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox.Flat' },
          { addon_plan: 'ref-AddonPlan-lightbox-standard',     plugin: 'ref-App::Plugin-ligthbox.Twit' },
          { addon_plan: 'ref-AddonPlan-api-standard',          plugin: 'ref-App::Plugin-api' }
          # { addon_plan: 'ref-AddonPlan-support-standard',      plugin: 'ref-App::Plugin-support' },
          # { addon_plan: 'ref-AddonPlan-support-vip',           plugin: 'ref-App::Plugin-support' }
        ]
      }
      references = {}

      seeds.each do |klass, new_record|
        new_record.each do |attributes|
          reference_key = "#{klass.to_s}-"
          reference_key += "#{attributes[:addon].sub(/\Aref-Addon-/, '')}-" if klass == AddonPlan
          reference_key += "#{attributes[:name] || attributes[:token]}"
          attributes = attributes.inject({}) { |h, (k, v)| h[k] = (v =~ /\Aref-/ ? references[v.sub(/\Aref-/, '')] : v); h }
          references[reference_key] = klass.create!(attributes, as: :admin)
        end
      end
      puts "Created:"
      puts "\t- #{App::Component.count} App::Components;"
      puts "\t- #{App::ComponentVersion.count} App::ComponentVersions;"
      puts "\t- #{App::Design.count} App::Designs;"
      puts "\t- #{Addon.count} Addons;"
      puts "\t- #{AddonPlan.count} AddonPlans;"
      puts "\t- #{App::Plugin.count} App::Plugins;"
      puts "\t- #{App::SettingsTemplate.count} App::SettingsTemplates;"
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

    # def player_components
    #   empty_tables(App::Component, App::ComponentVersion)
    #   names_token = {
    #     'app' => 'e',
    #     'subtitles' => 'bA'
    #   }
    #   versions = %w[2.0.0-alpha 2.0.0 1.1.0 1.0.0]
    #   version_zip = File.new(Rails.root.join('spec/fixtures/app/e.zip'))
    #   names_token.each do |name, token|
    #     component = App::Component.create({ name: name, token: token }, as: :admin)
    #     versions.each do |version|
    #       component.versions.create({ version: version, zip: version_zip }, as: :admin)
    #     end
    #   end
    # end

    def admins
      empty_tables(Admin)
      disable_perform_deliveries do
        puts "Creating admins..."
        BASE_USERS.each do |admin_info|
          Admin.create(email: admin_info[1], password: "123456")
          puts "Admin #{admin_info[1]}:123456"
        end
      end
    end

    def create_enthusiasts(user_id = nil)
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
      empty_tables("delayed_jobs")
    end

    def sites
      empty_tables(Site)
      delete_all_files_in_public('uploads/licenses')
      delete_all_files_in_public('uploads/loaders')
      Populate.users if User.all.empty?
      Populate.plans if Plan.all.empty?

      subdomains = %w[www blog my git sv ji geek yin yang chi cho chu foo bar rem]
      # created_at_array = (2.months.ago.to_date..Date.today).to_a

      User.all.each do |user|
        BASE_SITES.each do |hostname|
          if rand >= 0.5
            site = user.sites.create({ hostname: hostname, plan_id: Plan.where(name: %w[plus premium].sample, cycle: 'month').first.id }, without_protection: true)
            Service::Site.new(site).migrate_plan_to_addons
          else
            Service::Site.build_site(user: user, hostname: hostname).initial_save
          end
        end
      end

      empty_tables("delayed_jobs")
      puts "#{BASE_SITES.size} beautiful sites created for each user!"
    end

    # FIXME Remy: After the new add-on invoicing logic is coded
    def invoices(user_id = nil)
      empty_tables("invoices_transactions", InvoiceItem, Invoice, Transaction)
      users = user_id ? [User.find(user_id)] : User.all
      plans = Plan.standard_plans.all
      users.each do |user|
        user.sites.active.each do |site|
          (5 + rand(15)).times do |n|
            Timecop.travel(n.months.from_now) do
              # site.prepare_pending_attributes
              invoice = Service::Invoice.build(site: site).tap { |s| s.save }.invoice
              puts "Invoice created: $#{invoice.amount / 100.0}"
            end
          end
        end
      end
      empty_tables("delayed_jobs")
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
        VideoTag.where(st: site.token).delete_all
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
          VideoTag.create(st: site.token, u: "video#{video_i}",
            uo: "s",
            n: "Video #{video_i} long name test truncate",
            no: "s",
            cs: ["83cb4c27","83cb4c57","af355ec8", "af355ec9"],
            p: "http#{'s' if video_i.even?}://d1p69vb2iuddhr.cloudfront.net/assets/www/demo/midnight_sun_800-4f8c545242632c5352bc9da1addabcf5.jpg",
            z: "544x306",
            s: {
              "83cb4c27" => { u: "http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.mp4", q: "base", f: "mp4" },
              "83cb4c57" => { u: "http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.mp4", q: "hd", f: "mp4" },
              "af355ec8" => { u: "http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.webm", q: "base", f: "webm" },
              "af355ec9" => { u: "http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.webm", q: "hd", f: "webm" },
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
      puts "Fake users stats generated!"
    end

    def sites_stats
      empty_tables(Stats::SitesStat)
      day = 2.years.ago.midnight
      hash = { fr: 0, sp: 0, tr: { plus: { m: 0, y: 0 }, premium: { m: 0, y: 0 } }, pa: { plus: { m: 0, y: 0 }, premium: { m: 0, y: 0 } }, su: 0, ar: 0 }

      while day <= Time.now.utc.midnight
        hash[:d]   = day
        hash[:fr] += rand(50)
        hash[:sp] += rand(2)

        hash[:tr][:plus][:m]    += rand(10)
        hash[:tr][:plus][:y]    += rand(5)
        hash[:tr][:premium][:m] += rand(5)
        hash[:tr][:premium][:y] += rand(2)
        hash[:pa][:plus][:m]    += rand(7)
        hash[:pa][:plus][:y]    += rand(3)
        hash[:pa][:premium][:m] += rand(4)
        hash[:pa][:premium][:y] += rand(2)

        hash[:su] += rand(3)
        hash[:ar] += rand(6)

        Stats::SitesStat.create(hash)

        day += 1.day
      end
      puts "Fake sites stats generated!"
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
            Pusher["stats"].trigger('tick', json)

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
            Pusher["private-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
            json = { "md" => { "f" => { "d" => 1 }, "h" => { "d" => 1 } } }
            Pusher["private-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
            json = { "vv" => 1 }
            Pusher["private-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
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
                  Pusher["private-#{site.token}"].trigger_async('stats', json)
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
          st: site.token,
          u: generate_unique_token,
          uo: %w[a s].sample,
          n: Faker::Product.product,
          no: %w[a s].sample,
          p: 'http://media.jilion.com/vcg/ms_800.jpg',
          z: '400x320',
          cs: %w[5ABAC533 2ABFEFDA 97230509 4E855AFF],
          s: {
            '5ABAC533' => { u: 'http://media.jilion.com/vcg/ms_360p.mp4', q: 'base', f: 'mp4' },
            '2ABFEFDA' => { u: 'http://media.jilion.com/vcg/ms_720p.mp4', q: 'hd', f: 'mp4' },
            '97230509' => { u: 'http://media.jilion.com/vcg/ms_360p.webm', q: 'base', f: 'webm' },
            '4E855AFF' => { u: 'http://media.jilion.com/vcg/ms_720p.webm', q: 'hd', f: 'webm' }
          },
          d: (15 * 1000) + rand(2 * 60 * 60 * 1000),
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
          print "Deleting all files and directories in /public/#{path}\n"
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
      print "Deleting the content of #{tables.join(', ')}.. => "
      tables.each do |table|
        if table.is_a?(Class)
          table.delete_all
        else
          Site.connection.delete("DELETE FROM #{table} WHERE 1=1")
        end
      end
      puts "#{tables.join(', ')} empty!"
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
