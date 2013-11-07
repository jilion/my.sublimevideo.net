module InvoicesControllerHelper

  private

  def _retry_invoices(invoices)
    if invoices.present?
      if InvoicesCharger.new(invoices).charge
        flash[:notice] = t('invoice.retry_succeed')
      else
        flash[:alert] = t("transaction.errors.#{invoices.first.last_transaction.state}")
      end
    else
      flash[:notice] = t('invoice.no_invoices_to_retry')
    end
  end

end
