module UserModules::Scope
  extend ActiveSupport::Concern

  included do

    # billing
    scope :billable,                lambda { includes(:sites).merge(Site.billable) }
    scope :not_billable,            lambda { includes(:sites).where("(#{Site.billable.select("COUNT(sites.id)").where("sites.user_id = users.id").to_sql}) = 0") }
    scope :active_and_billable,     lambda { active.billable }
    scope :active_and_not_billable, lambda { active.not_billable }

    # credit card
    scope :without_cc, where(cc_type: nil, cc_last_digits: nil)
    scope :with_cc,    where { (cc_type != nil) & (cc_last_digits != nil) }

    # state
    scope :invited,           where { invitation_token != nil }
    scope :beta,              where { (invitation_token == nil) & (created_at < PublicLaunch.beta_transition_started_on.midnight) } # some beta users don't come from svs but were directly invited from msv!!
    scope :active,            where(state: 'active')

    # attributes queries
    scope :use_personal,      where(use_personal: true)
    scope :use_company,       where(use_company: true)
    scope :use_clients,       where(use_clients: true)
    scope :created_between,   lambda { |start_date, end_date| where { (created_at >= start_date) & (created_at < end_date) } }
    scope :signed_in_between, lambda { |start_date, end_date| where { (current_sign_in_at >= start_date) & (current_sign_in_at < end_date) } }

    # sort
    scope :by_name_or_email,   lambda { |way='asc'| order("users.name #{way.upcase}, users.email #{way.upcase}") }
    scope :by_sites_last_30_days_billable_video_views,  lambda { |way='desc'|
      joins(:sites).group(User.column_names.map { |c| "\"users\".\"#{c}\"" }.join(', ')).order("SUM(sites.last_30_days_main_video_views) + SUM(sites.last_30_days_extra_video_views) #{way}")
    }
    # TODO: To test
    # scope :by_sites_last_30_days_billable_video_views,  lambda { |way='desc'|
    #   joins(:sites).group(User.column_names.map { |c| "\"users\".\"#{c}\"" }.join(', ')).order { [sum(sites.last_30_days_main_video_views) + sum(sites.last_30_days_extra_video_views), way] }
    # }
    scope :by_last_invoiced_amount,  lambda { |way='desc'| order("users.last_invoiced_amount #{way.upcase}") }
    scope :by_total_invoiced_amount, lambda { |way='desc'| order("users.total_invoiced_amount #{way.upcase}") }
    scope :by_beta,                  lambda { |way='desc'| order("users.invitation_token #{way.upcase}") }
    scope :by_date,                  lambda { |way='desc'| order("users.created_at #{way.upcase}") }

  end

  module ClassMethods

    def search(q)
      includes(:sites).where {
        (lower(:email) =~ lower("%#{q}%")) |
        (lower(:name) =~ lower("%#{q}%")) |
        (lower(sites.hostname) =~ lower("%#{q}%")) |
        (lower(sites.dev_hostnames) =~ lower("%#{q}%"))
      }
    end

  end

end
