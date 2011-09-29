module InvoicesHelper

  def invoice_dates(invoice)
    if invoice.persisted?
      l(invoice.created_at, :format => :d_b_Y)
    else
      l(invoice.site.plan_cycle_ended_at.tomorrow, :format => :d_b_Y)
    end
  end

  def invoice_item_dates(invoice_item)
    "#{l(invoice_item.started_at, :format => :d_b_Y)} - #{l(invoice_item.ended_at, :format => :d_b_Y)}"
  end

  def charging_status(invoice)
    if invoice.open?
      "Not yet paid."
    elsif invoice.canceled?
      "Canceled."
    elsif invoice.failed?
      text = "#{content_tag(:strong, "Payment failed", :class => "failed")} on #{l(invoice.last_failed_at, :format => :minutes_timezone)}".html_safe
      unless invoice.last_transaction.error =~ /secure.ogone/ # FIXME we store the 3d secure html in this field,
                                                              # so if the 3d secure transaction fail, we don't want to show this ugly field
                                                              # we should clear this field after use (or something similar...)
        text += " with the following error: #{content_tag(:em, "\"#{truncate(invoice.last_transaction.error, :length => 50)}\"")}".html_safe
      end
      text + "."
    elsif invoice.refunded?
      "Paid on #{l(invoice.paid_at, :format => :minutes_timezone)}, refunded on #{l(invoice.site.refunded_at, :format => :minutes_timezone)}."
    elsif invoice.paid?
      "Paid on #{l(invoice.paid_at, :format => :minutes_timezone)}."
    elsif invoice.waiting?
      "Waiting payment confirmation."
    end
  end

  def stamp(invoice)
    if invoice.failed?
      'failed'
    elsif invoice.paid?
      invoice.refunded? ? 'refunded' : 'paid'
    else
      invoice.state
    end
  end

end
