require_dependency 'business_model'

module SiteModules::Scope
  extend ActiveSupport::Concern

  included do

    # state
    scope :active,       where{ state == 'active' }
    scope :inactive,     where{ state != 'active' }
    scope :suspended,    where{ state == 'suspended' }
    scope :archived,     where{ state == 'archived' }
    scope :not_archived, where{ state != 'archived' }
    # legacy
    scope :refunded,  where{ (state == 'archived') & (refunded_at != nil) }

    # attributes queries
    scope :with_wildcard,              where{ wildcard == true }
    scope :with_path,                  where{ (path != nil) & (path != '') & (path != ' ') }
    scope :badged,                     ->(bool) { where{ badged == bool } }
    scope :with_extra_hostnames,       where{ (extra_hostnames != nil) & (extra_hostnames != '') }
    scope :with_not_canceled_invoices, -> { joins(:invoices).merge(::Invoice.not_canceled) }

    # addons
    scope :paying, -> { includes(:billable_items).merge(BillableItem.subscribed).merge(BillableItem.paid) }

    # admin
    scope :user_id, ->(user_id) { where(user_id: user_id) }

    # sort
    scope :by_hostname,         ->(way = 'asc')  { order{ hostname.send(way) }.order{ token.send(way) } }
    scope :by_user,             ->(way = 'desc') { includes(:user).order{ user.name.send(way) }.order{ user.email.send(way) } }
    scope :by_state,            ->(way = 'desc') { order{ state.send(way) } }
    scope :by_plan_price,       ->(way = 'desc') { includes(:plan).order{ plan.price.send(way) } }
    scope :by_google_rank,      ->(way = 'desc') { where{ google_rank >= 0 }.order{ google_rank.send(way) } }
    scope :by_alexa_rank,       ->(way = 'desc') { where{ alexa_rank >= 1 }.order{ alexa_rank.send(way) } }
    scope :by_date,             ->(way = 'desc') { order{ created_at.send(way) } }
    scope :by_trial_started_at, ->(way = 'desc') { order{ trial_started_at.send(way) } }
    scope :by_last_30_days_video_tags, ->(way = 'desc') { order{ last_30_days_video_tags.send(way) } }
    scope :by_last_30_days_billable_video_views, ->(way = 'desc') {
      order("(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views + sites.last_30_days_embed_video_views) #{way}")
    }
    scope :with_min_billable_video_views, ->(min) {
      where("(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views + sites.last_30_days_embed_video_views) >= #{min}")
    }
    scope :by_last_30_days_extra_video_views_percentage, ->(way = 'desc') {
      order("CASE WHEN (sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views) > 0
      THEN (sites.last_30_days_extra_video_views / CAST(sites.last_30_days_main_video_views + sites.last_30_days_extra_video_views AS DECIMAL))
      ELSE -1 END #{way}")
    }

  end

  module ClassMethods

    def search(q)
      joins(:user).where{
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
