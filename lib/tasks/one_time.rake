# coding: utf-8
namespace :one_time do

  namespace :logs do
    desc "Reparse logs for site usages"
    task reparse: :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        SiteUsage.where(day: { "$gte" => beginning_of_month }).delete_all

        months_logs = Log.where(started_at: { "$gte" => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(priority: 299).parse_logs(months_logs_ids)
        puts "Delayed logs parsing from #{beginning_of_month}"
      end
    end

    desc "Reparse voxcast logs for user agent"
    task reparse_user_agent: :environment do
      timed do
        beginning_of_month = Time.now.utc.beginning_of_month
        UsrAgent.where(month: { "$gte" => beginning_of_month }).delete_all

        months_logs = Log::Voxcast.where(started_at: { "$gte" => beginning_of_month })
        months_logs_ids = months_logs.map(&:id)
        puts OneTime::Log.delay(priority: 299).parse_logs_for_user_agents(months_logs_ids)
        puts "Delayed Voxcast logs parsing for user agent from #{beginning_of_month}"
      end
    end

    task parse_unparsed_logs: :environment do
      count = Log::Voxcast.where(parsed_at: nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log.delay(priority: 100).parse_log(id) }
        skip += 1000
      end
    end
  end

  namespace :users do
    desc "Set users' name from users' current first and last name"
    task set_name_from_first_and_last_name: :environment do
      timed { puts OneTime::User.set_name_from_first_and_last_name }
    end

    desc "Set users' billing name from users' name"
    task set_billing_info: :environment do
      timed { puts OneTime::User.set_billing_info }
    end
  end

  namespace :plans do
    desc "Create the V2 plans"
    task create_v2_plans: :environment do
      timed { puts OneTime::Plan.create_v2_plans }
    end
  end

  namespace :sites do
    desc "Reset sites caches"
    task reset_caches: :environment do
      timed { Site.all.each { |site| site.delay(priority: 400).reset_caches! } }
    end

    desc "Parse all unparsed user_agents logs"
    task parse_user_agents_logs: :environment do
      count = Log::Voxcast.where(user_agents_parsed_at: nil).count
      skip  = 0
      while skip < count
        ids = Log::Voxcast.where(user_agents_parsed_at: nil).only(:id).limit(1000).skip(skip).map(&:id)
        ids.each { |id| Log::Voxcast.delay(priority: 90, run_at: 1.minute.from_now).parse_log_for_user_agents(id) }
        skip += 1000
      end
    end

    desc "Re-generate loader and license templates for all sites"
    task regenerate_all_loaders_and_licenses: :environment do
      timed { puts OneTime::Site.regenerate_all_loaders_and_licenses }
    end

    desc "Set trial_started_at for sites created before v2"
    task set_trial_started_at_for_sites_created_before_v2: :environment do
      timed { puts OneTime::Site.set_trial_started_at_for_sites_created_before_v2 }
    end

    desc "Migrate current sites' plans to new business model plans"
    task current_sites_plans_migration: :environment do
      timed { puts OneTime::Site.current_sites_plans_migration }
    end

    desc "Set sites' badged attribute"
    task set_badged: :environment do
      timed { puts OneTime::Site.set_badged }
    end

    desc "Update last 30 days counters of all not archived sites"
    task update_last_30_days_counters_for_not_archived_sites: :environment do
      timed { Site.update_last_30_days_counters_for_not_archived_sites }
    end
  end

  namespace :stats do

    task calculate_beta_users: :environment do
      Stats::UsersStat.where(d: { "$lt" => Time.utc(2011,3,30) }).delete_all

      day = Time.utc(2010,9,14)
      beta_sum, archived_sum = 0, 0
      while day < Time.utc(2011,3,30) do
        beta_new_count = User.beta.where { (date_trunc('day', created_at) == day.midnight) & ((archived_at == nil) | (archived_at > day.midnight)) }.count
        beta_archived_count = User.beta.where { date_trunc('day', archived_at) == day.midnight }.count
        beta_sum += beta_new_count - beta_archived_count
        puts "On #{day}, there was #{beta_sum} beta users (#{beta_new_count} new and #{beta_archived_count} archived)."

        archived_sum += User.where { date_trunc('day', archived_at) == day.midnight }.count
        s = Stats::UsersStat.create!(
          d:  day,
          be: beta_sum,
          fr: 0,
          pa: 0,
          su: 0,
          ar: archived_sum
        )
        day += 1.day
      end

      Stats::UsersStat.where(be: nil).each do |stat|
        stat.update_attributes(be: 0)
      end
    end

    task calculate_beta_sites: :environment do
      Stats::SitesStat.where(d: { "$lt" => Time.utc(2011,3,30) }).delete_all

      day = Time.utc(2010,9,14)
      beta_sum, archived_sum = 0, 0
      while day < Time.utc(2011,3,30) do
        beta_new_count = Site.where { (date_trunc('day', created_at) == day.midnight) & ((archived_at == nil) | (archived_at > day.midnight)) }.count
        archived_count = Site.where { date_trunc('day', archived_at) == day.midnight }.count
        beta_sum += beta_new_count - archived_count
        archived_sum += archived_count
        puts "On #{day}, there was #{beta_sum} beta sites (#{beta_new_count} new and #{archived_count} archived)."

        s = Stats::SitesStat.create!(
          d:  day,
          fr: {
            beta: beta_sum,
            dev: 0,
            free: 0
          },
          sp: 0,
          tr: {
            plus: { m: 0, y: 0 },
            premium: { m: 0, y: 0 }
          },
          pa: {
            plus: {
              m: 0,
              y: 0
            },
            premium: {
              m: 0,
              y: 0
            }
          },
          su: 0,
          ar: archived_sum
        )
        day += 1.day
      end
    end

    task fix_dev_sites: :environment do
      day = Time.utc(2010,9,14)
      archived_dev_count_sum = 0
      while day < Time.utc(2011,11,30) do
        archived_dev_count = Site.in_plan(['dev', 'beta']).where { date_trunc('day', archived_at) == day.midnight }.count
        archived_dev_count_sum += archived_dev_count

        stat = Stats::SitesStat.where(d: day).first
        old_stat_fr_dev = stat.fr['dev']
        stat.fr['dev'] -= archived_dev_count_sum
        stat.save!
        puts "On #{day}, there was #{old_stat_fr_dev} dev sites, there are now #{stat.fr['dev']} (#{archived_dev_count_sum} sites less)."

        day += 1.day
      end
    end

    desc "Migrate old to new Stats::UsersStats & Stats::SitesStats"
    task migrate_old_stats: :environment do
      timed do
        Stats::UsersStat.where(d: nil).each do |stat|
          stat.update_attributes(
            d:  stat.created_at.midnight,
            fr: stat.states_count['active_and_not_billable_count'],
            pa: stat.states_count['active_and_billable_count'],
            su: stat.states_count['suspended_count'],
            ar: stat.states_count['archived_count']
          )
        end

        beta_plan_id      = Plan.where { name == 'beta' }.first.id
        dev_plan_id       = Plan.where { name == 'dev' }.first.id
        free_plan_id      = Plan.free_plan.id
        sponsored_plan_id = Plan.sponsored_plan.id
        comet_m_id        = Plan.where { (name == 'comet') & (cycle == 'month') }.first.id
        comet_y_id        = Plan.where { (name == 'comet') & (cycle == 'year') }.first.id
        planet_m_id       = Plan.where { (name == 'planet') & (cycle == 'month') }.first.id
        planet_y_id       = Plan.where { (name == 'planet') & (cycle == 'year') }.first.id
        star_m_id         = Plan.where { (name == 'star') & (cycle == 'month') }.first.id
        star_y_id         = Plan.where { (name == 'star') & (cycle == 'year') }.first.id
        galaxy_m_id       = Plan.where { (name == 'galaxy') & (cycle == 'month') }.first.id
        galaxy_y_id       = Plan.where { (name == 'galaxy') & (cycle == 'year') }.first.id

        plus_m_id    = Plan.where { (name == 'plus') & (cycle == 'month') }.first.id
        plus_y_id    = Plan.where { (name == 'plus') & (cycle == 'year') }.first.id
        premium_m_id = Plan.where { (name == 'premium') & (cycle == 'month') }.first.id
        premium_y_id = Plan.where { (name == 'premium') & (cycle == 'year') }.first.id

        Stats::SitesStat.where(d: nil).each do |stat|
          stat.update_attributes(
            d:  stat.created_at.midnight,
            fr: {
              beta: stat.plans_count[beta_plan_id.to_s].to_i,
              dev: stat.plans_count[dev_plan_id.to_s].to_i,
              free: stat.plans_count[free_plan_id.to_s].to_i
            },
            sp: stat.plans_count[sponsored_plan_id.to_s].to_i,
            tr: {
              plus: { m: 0, y: 0 },
              premium: { m: 0, y: 0 }
            },
            pa: {
              plus: {
                m: 0, # stat.plans_count[comet_m_id.to_s].to_i + stat.plans_count[planet_m_id.to_s].to_i + stat.plans_count[plus_m_id.to_s].to_i,
                y: 0 # stat.plans_count[comet_y_id.to_s].to_i + stat.plans_count[planet_y_id.to_s].to_i + stat.plans_count[plus_y_id.to_s].to_i
              },
              premium: {
                m: 0, # stat.plans_count[star_m_id.to_s].to_i + stat.plans_count[galaxy_m_id.to_s].to_i + stat.plans_count[premium_m_id.to_s].to_i,
                y: 0 # stat.plans_count[star_y_id.to_s].to_i + stat.plans_count[galaxy_y_id.to_s].to_i + stat.plans_count[premium_y_id.to_s].to_i
              }
            },
            su: stat.states_count['suspended'].to_i,
            ar: stat.states_count['archived'].to_i
          )
        end
      end
    end

    desc "Merge duplicate VideoStats and delete bad VideoTags based on wrong CRC32 generation (? params included)"
    task merge_duplicate_video_stats_and_delete_bad_video_tags: :environment do
      timed do
        site_tokens = [
          '2xrynuh2', 'lfmxr9gt', 'g39fmpp1', '1gt8yor7', '7k9odjzv', 'txohtl11', 'vfzh18bi', '2l7axk8c', 'iaruw1qi', 'avd44aef', 'nn8698ww',
          '4aeqofw0', 'nne3u3qd', 'h5qegk5j', 'op0mkqtn', 'suwutgs8', 'rrj45mbt', 'uvrkjs6y', '87r9xy5e', '0apmxu9m', 'bo6onvdp', 't1el7q92',
          'wtlrh4a1', '8pettr2l', 'ovjigy83', 'ipemdsdc', '8z30ym0w', '5ataduh2', 'mtrrhukx', 'wwaswim5', 'f5n04h63', '4md5tnvw', 'd4jhdmde',
          '29a31wy1', 'kaxf52ke', 'jag8liea', 'q87gxah0', 'alv676x0', 'b13hmic3', 'qn3ort3a', 'q7z31dji', 'pn1nfhuj', '7aph6o5g', '8hgvyvlc',
          'wsj6kezk', 'd8rjro54', '9pkh3pou', 'erfb5jxm', 'eq916p01', '7l6sr5hh', 'j9q1y3m1', '95ahxpcg', 'why96mtw', 'oqdmk4t6', 'xqnzpou9',
          'j0lqevol', 'lbshmaxk', 'lv9n9gdv', 'dsopijh8', 'fq1qtj48', '83y67ght', '8e7bgm4a', '3w98phzh', 'r7mul5tt', '2b4x0kwg', 'y7areitu',
          'o8ptoe09', 'ai42982g', 'oaiknkun', 'm0lzy3xt', 'quq4zs1k', 'ybjtuko4', 'gf2gv810', '0l5c6oby', 'ytxg2sy5', 'ykfg8c0a', 'j4nw7nem',
          'aoq66s9z', '7b8nn1v4', 'd67d4bn4', 'jpjr8p4d', '9majtpzr', 'mmvg0rfl', 'v8tqssb9', 'tbhdl70s', 'szejjut1', 'uo742m30', '2ir8o5ky',
          'ngyd2tdi', '3y0866sj', 'mur4c2aa', 'mkkaahxf', 'jv4dcx3o', '6j4zanab', 'jx5qyjz1', '55woyzoi', 'q43b92jx', '7gd9zazc', '6n6lb66i',
          'fj76pfnh', 'l45d3c3u', 'ikfqgbx0', 'kpcxti7e', '4ot5x0w2', 'ibvjcopp', 'pczql2wt', 'xwccapc5', '9cu26xxg', '4ptfsgbk', '0ljd7qrk',
          'mb27lban', '8vnlactg', 'rm8w0f9k', 'qdvuigm7', 'vwftwdte', 'estq9huv', 'ihuf4f5u', 'kq8zmtdf', 'uazs3te5', 'ql0355zz', 'y5uk4rpd',
          '6pdo240s', 'qeiwa7fu', 'qsr700iv'
        ]
        # Site.where(token: '2xrynuh2') do |site|
        # Site.where { last_30_days_main_video_views > 0 }.find_each(batch_size: 100) do |site|

          # VideoTag.where(st: site.token).only(:s).each do |video_tag|
        criteria = VideoTag.where(st: { '$nin' => site_tokens }, uo: { '$ne' => nil })
        counter = criteria.count
        puts "#{site_tokens.uniq.size} sites with VideoTag including ?"
        puts "#{counter} VideoTag not scanned yet."
        while counter > 0
          counter -= 1000
          counter = 0 if counter < 0
          puts "left #{counter}"
          criteria.offset(counter).limit(1000).each do |video_tag|
            next if site_tokens.include?(video_tag.st)
            video_tag.s.values.each do |source|
              if source['u'].include?('?')
                puts "? in video source found for site: #{video_tag.st})"
                site_tokens << video_tag.st
                break
              end
            end
          end
        end
        puts "+++++++++++++++++++"
        puts site_tokens
      end
    end
  end

end