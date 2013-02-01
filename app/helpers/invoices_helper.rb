module InvoicesHelper

  def invoice_dates(invoice)
    l(invoice.created_at, format: :d_b_Y)
  end

  def invoice_item_title(invoice_item)
    case invoice_item.class.to_s
    when 'InvoiceItem::Plan'
      invoice_item.item.title
    when 'InvoiceItem::AppDesign'
      'Design: ' + invoice_item.item.title
    when 'InvoiceItem::AddonPlan'
      'Add-on: ' + invoice_item.item.title
    end
  end

  def invoice_item_dates(invoice_item)
    end_day = invoice_item.ended_at == invoice_item.ended_at.end_of_day ? invoice_item.ended_at : (invoice_item.ended_at - 1.day).end_of_day
    "#{l(invoice_item.started_at, format: :d_b_Y)} - #{l(end_day, format: :d_b_Y)}"
  end

  def charging_status(invoice)
    if invoice.open?
      "Not yet paid."
    elsif invoice.canceled?
      "Canceled."
    elsif invoice.failed?
      text = "#{content_tag(:strong, "Payment failed", class: "failed")} on #{l(invoice.last_failed_at, format: :minutes_timezone)}".html_safe
      unless invoice.last_transaction.error =~ /secure.ogone/ # FIXME we store the 3d secure html in this field,
                                                              # so if the 3d secure transaction fail, we don't want to show this ugly field
                                                              # we should clear this field after use (or something similar...)
        text += " with the following error: #{content_tag(:em, "\"#{truncate(invoice.last_transaction.error, length: 50)}\"")}".html_safe
      end
      text + "."
    elsif invoice.refunded?
      "Paid on #{l(invoice.paid_at, format: :minutes_timezone)}, refunded on #{l(invoice.site.refunded_at, format: :minutes_timezone)}."
    elsif invoice.paid?
      "Paid on #{l(invoice.paid_at, format: :minutes_timezone)}."
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
