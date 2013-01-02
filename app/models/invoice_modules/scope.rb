module InvoiceModules::Scope
  extend ActiveSupport::Concern

  included do

    scope :paid_between, lambda { |started_at, ended_at| between(paid_at: started_at..ended_at) }

    scope :open,           where(state: 'open')
    scope :paid,           where(state: 'paid').includes(:site).where{ sites.refunded_at == nil }
    scope :refunded,       where(state: 'paid').includes(:site).where{ sites.refunded_at != nil }
    scope :failed,         where(state: 'failed')
    scope :waiting,        where(state: 'waiting')
    scope :canceled,       where(state: 'canceled')
    scope :open_or_failed, where(state: %w[open failed])
    scope :not_canceled,   where{ state != 'canceled' }
    scope :not_paid,       where(state: %w[open waiting failed])
    scope :renew,          lambda { |bool=true| where(renew: bool) }
    scope :site_id,        lambda { |site_id| where(site_id: site_id) }
    scope :user_id,        lambda { |user_id| joins(:user).where{ user.id == user_id } }

    scope :for_month, ->(date) {
      not_canceled.includes(:invoice_items)
      .where { invoice_items.started_at >= date.beginning_of_month }.where { invoice_items.started_at <= date.end_of_month }
      .where { invoice_items.ended_at >= date.beginning_of_month }.where { invoice_items.ended_at <= date.end_of_month }
    }

    # sort
    scope :by_id,                  lambda { |way='desc'| order("invoices.id #{way}") }
    scope :by_date,                lambda { |way='desc'| order("invoices.created_at #{way}") }
    scope :by_amount,              lambda { |way='desc'| order("invoices.amount #{way}") }
    scope :by_user,                lambda { |way='desc'| joins(:user).order("users.name #{way}, users.email #{way}") }
    scope :by_invoice_items_count, lambda { |way='desc'| order("invoices.invoice_items_count #{way}") }

  end

  module ClassMethods

    def search(q)
      joins(:site, :user).where{
        (lower(user.email) =~ lower("%#{q}%")) |
        (lower(user.name) =~ lower("%#{q}%")) |
        (lower(site.hostname) =~ lower("%#{q}%")) |
        (lower(reference) =~ lower("%#{q}%"))
      }
    end

  end

end
