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
      "Not paid yet"
    elsif invoice.paid?
      "Paid on #{l(invoice.paid_at, :format => :minutes_timezone)}"
    elsif invoice.failed?
      "#{content_tag(:strong, "Payment failed")} on #{l(invoice.failed_at, :format => :minutes_timezone)} with the following error: #{content_tag(:em, "\"#{invoice.last_failed_transaction.error}\"")}".html_safe
    end
  end

  def invoice_items_grouped_by_site(invoice, options={})
    invoice_items = invoice.invoice_items
    invoice_items = invoice_items.where(site_id: options[:site_id]) if options[:site_id]
    invoice_items.group_by { |invoice_item| invoice_item.site }.sort { |a,b| a[0].hostname <=> b[0].hostname }
  end

  def get_plan_invoice_item(invoice_items)
    invoice_items.detect { |invoice_item| invoice_item.type == 'InvoiceItem::Plan' }
  end

end
