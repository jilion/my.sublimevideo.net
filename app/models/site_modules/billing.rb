require_dependency 'business_model'

module SiteModules::Billing
  extend ActiveSupport::Concern

  %w[open failed waiting].each do |invoice_state|
    define_method :"invoices_#{invoice_state}?" do
      invoices.any? { |i| i.send("#{invoice_state}?") }
    end
  end

  def refunded?
    archived? && refunded_at?
  end

  def last_paid_invoice
    invoices.paid.order(:paid_at).try(:last)
  end

end
