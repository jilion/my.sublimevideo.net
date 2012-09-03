require_dependency 'public_launch'

module UserModules::Scope
  extend ActiveSupport::Concern

  included do

    # billing
    scope :free, lambda {
      active.includes(:sites).where("(#{Site.in_paid_plan.select("COUNT(sites.id)").where("sites.user_id = users.id").to_sql}) = 0")
    }
    scope :paying, lambda {
      active.includes(:sites).merge(Site.in_paid_plan)
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
    scope :created_on,        lambda { |date| where { created_at >> date.all_day } }
    scope :newsletter,        lambda { |bool=true| where { newsletter == bool } }
    scope :vip,               lambda { |bool=true| where { vip == bool } }

    scope :sites_tagged_with, lambda { |word| joins(:sites).merge(Site.not_archived.tagged_with(word)) }

    # sort
    scope :by_name_or_email,         lambda { |way='asc'| order("users.name #{way.upcase}, users.email #{way.upcase}") }
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
