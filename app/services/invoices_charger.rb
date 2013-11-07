class InvoicesCharger

  def initialize(invoices)
    @invoices = invoices
  end

  def charge
    if @invoices.present?
      transaction = Transaction.charge_by_invoice_ids(@invoices.map(&:id))

      transaction.paid?
    else
      true
    end
  end

end
