# coding: utf-8
require_dependency 'public_launch'

module UserModules::Scope
  extend ActiveSupport::Concern

  included do

    # state
    scope :invited,      -> { where{ invitation_token != nil } }
    # some beta users don't come from svs but were directly invited from msv!!
    scope :beta,         -> { where{ (invitation_token == nil) & (created_at < PublicLaunch.beta_transition_started_on.midnight) } }
    scope :active,       -> { where{ state == 'active' } }
    scope :inactive,     -> { where{ state != 'active' } }
    scope :suspended,    -> { where{ state == 'suspended' } }
    scope :archived,     -> { where{ state == 'archived' } }
    scope :not_archived, -> { where{ state != 'archived' } }

    # billing
    scope :paying,     -> { active.includes(:sites, :billable_items).merge(Site.paying) }
    scope :paying_ids, -> { active.select("DISTINCT(users.id)").joins("INNER JOIN sites ON sites.user_id = users.id INNER JOIN billable_items ON billable_items.site_id = sites.id").merge(BillableItem.subscribed).merge(BillableItem.paid) }
    scope :free,       -> { active.where{ id << User.paying_ids } }

    # credit card
    scope :without_cc,           -> { where(cc_type: nil, cc_last_digits: nil) }
    scope :with_cc,              -> { where{ (cc_type != nil) & (cc_last_digits != nil) } }
    scope :cc_expire_this_month, -> { where(cc_expire_on: Time.now.utc.end_of_month.to_date) }
    scope :with_balance,         -> { where{ balance > 0 } }
    scope :last_credit_card_expiration_notice_sent_before, ->(date) {
        where { last_credit_card_expiration_notice_sent_at < date }
    }

    # attributes queries
    scope :created_on,   ->(date) { where { created_at >> date.all_day } }
    scope :use_personal, ->(bool = true) { where(use_personal: bool) }
    scope :use_company,  ->(bool = true) { where(use_company: bool) }
    scope :use_clients,  ->(bool = true) { where(use_clients: bool) }
    scope :newsletter,   ->(bool = true) { where(newsletter: bool) }
    scope :vip,          ->(bool = true) { where(vip: bool) }

    scope :sites_tagged_with, ->(word) { joins(:sites).merge(Site.not_archived.tagged_with(word)) }

    scope :voxcast_users,   -> { active.includes(:sites).where(sites: { id: SiteUsage.site_ids_with_loader_hits }) }
    scope :with_page_loads, -> { active.includes(:sites).merge(Site.with_page_loads) }

    # sort
    scope :by_name_or_email,         ->(way = 'asc') { order("users.name #{way.upcase}, users.email #{way.upcase}") }
    scope :by_last_invoiced_amount,  ->(way = 'desc') { order("users.last_invoiced_amount #{way.upcase}") }
    scope :by_total_invoiced_amount, ->(way = 'desc') { order("users.total_invoiced_amount #{way.upcase}") }
    scope :by_beta,                  ->(way = 'desc') { order("users.invitation_token #{way.upcase}") }
    scope :by_date,                  ->(way = 'desc') { order("users.created_at #{way.upcase}") }

    scope :search, ->(q) {
      includes(:sites).where{
        (lower(:email) =~ lower("%#{q}%")) | (lower(:name) =~ lower("%#{q}%")) |
        (lower(sites.hostname) =~ lower("%#{q}%")) | (lower(sites.dev_hostnames) =~ lower("%#{q}%"))
      }
    }
  end

end
