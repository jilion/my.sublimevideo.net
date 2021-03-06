module SiteModules::Billing
  extend ActiveSupport::Concern

  %w[open failed waiting].each do |invoice_state|
    define_method :"invoices_#{invoice_state}?" do
      invoices.with_state(invoice_state).any?
    end
  end

  def refunded?
    archived? && refunded_at?
  end

end
