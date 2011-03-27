module InvoicesHelper

  def invoice_dates(invoice)
    if invoice.persisted?
      l(invoice.created_at, :format => :d_b_Y)
    else#if invoice.site.plan_cycle_ended_at?
      l(invoice.site.plan_cycle_ended_at.tomorrow, :format => :d_b_Y)
    end
  end

  def invoice_item_dates(invoice_item)
    "#{l(invoice_item.started_at, :format => :d_b_Y)} - #{l(invoice_item.ended_at, :format => :d_b_Y)}"
  end

  def charging_status(invoice)
    if invoice.open?
      "Not paid yet."
    elsif invoice.paid?
      "Paid on #{l(invoice.paid_at, :format => :minutes_timezone)}."
    elsif invoice.failed?
      "#{content_tag(:strong, "Payment failed")} on #{l(invoice.last_failed_at, :format => :minutes_timezone)}.".html_safe
      # unless invoice.last_failed_transaction.error =~ /secure.ogone/
      #   text += "with the following error: #{content_tag(:em, "\"#{invoice.last_failed_transaction.error}\"")}".html_safe
      # end
    end
  end

end
