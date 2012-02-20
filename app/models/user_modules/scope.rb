module UserModules::Scope
  extend ActiveSupport::Concern

  included do

    # billing
    scope :free, lambda {
      active.includes(:sites).where("(#{Site.active.paid_plan.not_in_trial.select("COUNT(sites.id)").where("sites.user_id = users.id").to_sql}) = 0")
    }
    scope :paying, lambda {
      active.includes(:sites).merge(Site.active.paid_plan.not_in_trial)
    }

    # credit card
    scope :without_cc,   where(cc_type: nil, cc_last_digits: nil)
    scope :with_cc,      where { (cc_type != nil) & (cc_last_digits != nil) }
    scope :with_balance, where { balance > 0 }

    # state
    scope :invited, where { invitation_token != nil }
    scope :beta,    where { (invitation_token == nil) & (created_at < PublicLaunch.beta_transition_started_on.midnight) } # some beta users don't come from svs but were directly invited from msv!!
    scope :active,       where { state == 'active' }
    scope :inactive,     where { state != 'active' }
    scope :suspended,    where { state == 'suspended' }
    scope :archived,     where { state == 'archived' }
    scope :not_archived, where { state != 'archived' }

    # attributes queries
    scope :use_personal,      lambda { |bool=true| where { use_personal == bool } }
    scope :use_company,       lambda { |bool=true| where { use_company == bool } }
    scope :use_clients,       lambda { |bool=true| where { use_clients == bool } }
    scope :created_between,   lambda { |start_date, end_date| where { (created_at >= start_date) & (created_at < end_date) } }
    scope :signed_in_between, lambda { |start_date, end_date| where { (current_sign_in_at >= start_date) & (current_sign_in_at < end_date) } }
    scope :newsletter,        lambda { |bool=true| where { newsletter == bool } }

    # sort
    scope :by_name_or_email, lambda { |way='asc'| order("users.name #{way.upcase}, users.email #{way.upcase}") }
    scope :by_sites_last_30_days_billable_video_views, lambda { |way='desc'|
      joins(:sites).group(User.column_names.map { |c| "\"users\".\"#{c}\"" }.join(', ')).order("SUM(sites.last_30_days_main_video_views) + SUM(sites.last_30_days_extra_video_views) + SUM(sites.last_30_days_embed_video_views) #{way}")
    }
    scope :by_last_invoiced_amount,  lambda { |way='desc'| order("users.last_invoiced_amount #{way.upcase}") }
    scope :by_total_invoiced_amount, lambda { |way='desc'| order("users.total_invoiced_amount #{way.upcase}") }
    scope :by_beta,                  lambda { |way='desc'| order("users.invitation_token #{way.upcase}") }
    scope :by_date,                  lambda { |way='desc'| order("users.created_at #{way.upcase}") }

  end

  module ClassMethods

    def search(q)
      includes(:sites).where {
        (lower(:email) =~ lower("%#{q}%")) | (lower(:name) =~ lower("%#{q}%")) |
        (lower(sites.hostname) =~ lower("%#{q}%")) | (lower(sites.dev_hostnames) =~ lower("%#{q}%"))
      }
    end

  end

end
