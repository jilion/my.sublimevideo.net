# coding: utf-8
require_dependency 'public_launch'

module UserModules::Scope
  extend ActiveSupport::Concern

  included do

    # billing
    scope :paying, -> { active.includes(:sites, :addonships).merge(::Addons::Addonship.subscribed).where{ addonships.addon_id >> Addons::Addon.paid.pluck(:id) } }
    scope :free,   -> { active.where("(#{User.paying.select("COUNT(sites.id)").where{ sites.user_id == id }.to_sql}) = 0") }

    # credit card
    scope :without_cc,           -> { where(cc_type: nil, cc_last_digits: nil) }
    scope :with_cc,              -> { where{ (cc_type != nil) & (cc_last_digits != nil) } }
    scope :cc_expire_this_month, -> { where(cc_expire_on: Time.now.utc.end_of_month.to_date) }
    scope :with_balance,         -> { where{ balance > 0 } }

    # state
    scope :invited,      where{ invitation_token != nil }
    scope :beta,         where{ (invitation_token == nil) & (created_at < PublicLaunch.beta_transition_started_on.midnight) } # some beta users don't come from svs but were directly invited from msv!!
    scope :active,       where{ state == 'active' }
    scope :inactive,     where{ state != 'active' }
    scope :suspended,    where{ state == 'suspended' }
    scope :archived,     where{ state == 'archived' }
    scope :not_archived, where{ state != 'archived' }

    # attributes queries
    scope :created_on,   ->(date) { where { created_at >> date.all_day } }
    scope :use_personal, ->(bool = true) { where(use_personal: bool) }
    scope :use_company,  ->(bool = true) { where(use_company: bool) }
    scope :use_clients,  ->(bool = true) { where(use_clients: bool) }
    scope :newsletter,   ->(bool = true) { where(newsletter: bool) }
    scope :vip,          ->(bool = true) { where(vip: bool) }

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
      includes(:sites).where{
        (lower(:email) =~ lower("%#{q}%")) | (lower(:name) =~ lower("%#{q}%")) |
        (lower(sites.hostname) =~ lower("%#{q}%")) | (lower(sites.dev_hostnames) =~ lower("%#{q}%"))
      }
    end

  end

end
