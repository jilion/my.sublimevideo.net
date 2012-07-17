require_dependency 'business_model'

module SiteModules::Scope
  extend ActiveSupport::Concern

  included do

    # usage_monitoring scopes
    scope :overusage_notified, where { overusage_notification_sent_at != nil }

    # state
    scope :active,       where { state == 'active' }
    scope :inactive,     where { state != 'active' }
    scope :suspended,    where { state == 'suspended' }
    scope :archived,     where { state == 'archived' }
    scope :not_archived, where { state != 'archived' }
    # legacy
    scope :refunded,  where { (state == 'archived') & (refunded_at != nil) }

    # attributes queries
    scope :with_wildcard,              where { wildcard == true }
    scope :with_path,                  where { (path != nil) & (path != '') & (path != ' ') }
    scope :badged,                     lambda { |bool| where { badged == bool } }
    scope :with_extra_hostnames,       where { (extra_hostnames != nil) & (extra_hostnames != '') }
    scope :with_plan,                  where { plan_id != nil }
    scope :with_next_cycle_plan,       where { next_cycle_plan_id != nil }
    scope :with_not_canceled_invoices, lambda { joins(:invoices).merge(::Invoice.not_canceled) }

    # plans
    scope :in_plan_id,     lambda { |plan_ids| active.where { plan_id >> Array.wrap(plan_ids) } }
    scope :in_plan,        lambda { |plan_names| in_plan_id(Plan.where { name >> Array.wrap(plan_names) }.map(&:id)) }
    scope :in_custom_plan, lambda { in_plan_id(Plan.custom_plans.map(&:id)) }
    scope :in_paid_plan,   lambda { in_plan_id(Plan.paid_plans.map(&:id)) }
    scope :in_trial,       lambda { in_plan('trial') }

    # billing
    scope :trial_ended, lambda {
      active.in_trial.where { (plan_started_at || BusinessModel.days_for_trial.days.ago) <= BusinessModel.days_for_trial.days.ago }
    }
    scope :trial_expires_on, lambda { |timestamp|
      active.where { date_trunc('day', plan_started_at) == (timestamp - BusinessModel.days_for_trial.days).midnight }
    }

    # plan cycles
    scope :renewable, lambda {
      active.where { (plan_cycle_ended_at < Time.now.utc) & (pending_plan_id == nil) }
    }
    scope :plan_will_be_renewed_on, lambda { |timestamp|
      active.where { date_trunc('day', plan_cycle_ended_at) == (timestamp - 1.day).midnight }
    }

    # admin
    scope :user_id,         lambda { |user_id| where(user_id: user_id) }
    scope :created_between, lambda { |start_date, end_date| where { (created_at >= start_date) & (created_at < end_date) } }

    # sort
    scope :by_hostname,         lambda { |way = 'asc'| order(:hostname.send(way), :token.send(way)) }
    scope :by_user,             lambda { |way = 'desc'| includes(:user).order(users: [:name.send(way), :email.send(way)]) }
    scope :by_state,            lambda { |way = 'desc'| order(:state.send(way)) }
    scope :by_plan_price,       lambda { |way = 'desc'| includes(:plan).order(plans: :price.send(way)) }
    scope :by_google_rank,      lambda { |way = 'desc'| where { google_rank >= 0 }.order(:google_rank.send(way)) }
    scope :by_alexa_rank,       lambda { |way = 'desc'| where { alexa_rank >= 1 }.order(:alexa_rank.send(way)) }
    scope :by_date,             lambda { |way = 'desc'| order(:created_at.send(way)) }
    scope :by_trial_started_at, lambda { |way = 'desc'| order(:trial_started_at.send(way)) }
    scope :by_last_30_days_video_tags, lambda { |way = 'desc'| order(:last_30_days_video_tags.send(way)) }
    scope :by_last_30_days_billable_video_views, lambda { |way = 'desc'|
      order("(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views + sites.last_30_days_embed_video_views) #{way}")
    }
    scope :with_min_billable_video_views, lambda { |min|
      where("(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views + sites.last_30_days_embed_video_views) >= #{min}")
    }
    scope :by_last_30_days_extra_video_views_percentage, lambda { |way = 'desc'|
      order("CASE WHEN (sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views) > 0
      THEN (sites.last_30_days_extra_video_views / CAST(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views AS DECIMAL))
      ELSE -1 END #{way}")
    }
    scope :by_last_30_days_plan_usage_percentage, lambda { |way = 'desc'|
      includes(:plan).
      order("CASE WHEN (sites.plan_id IS NOT NULL AND plans.video_views > 0)
      THEN ((sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views) / CAST(plans.video_views AS DECIMAL))
      ELSE -1 END #{way}")
    }

  end

  module ClassMethods

    def search(q)
      joins(:user).where {
        (lower(user.email) =~ lower("%#{q}%")) |
        (lower(user.name) =~ lower("%#{q}%")) |
        (lower(:token) =~ lower("%#{q}%")) |
        (lower(:hostname) =~ lower("%#{q}%")) |
        (lower(:dev_hostnames) =~ lower("%#{q}%")) |
        (lower(:extra_hostnames) =~ lower("%#{q}%"))
      }
    end

  end

end
