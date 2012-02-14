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

    task fix_beta_sites: :environment do
      day = Time.utc(2010,9,14)
      beta_sum, archived_sum = 0, 0
      while day < Time.utc(2011,4,17) do
        beta_new_count = Site.where { (created_at < PublicLaunch.beta_transition_started_on.midnight) & (date_trunc('day', created_at) == day.midnight) & ((archived_at == nil) | (archived_at > day.midnight)) }.count
        archived_count = Site.where { (created_at < PublicLaunch.beta_transition_started_on.midnight) & (date_trunc('day', archived_at) == day.midnight) }.count
        beta_sum += beta_new_count - archived_count
        archived_sum += archived_count

        stat = Stats::SitesStat.where(d: day).first
        old_stat_fr_beta = stat.fr['beta']
        stat.fr['beta'] = beta_sum
        stat.save!
        puts "On #{day}, there was #{old_stat_fr_beta} beta sites, there are now #{stat.fr['beta']} (#{archived_count} sites less)."
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
  end

end