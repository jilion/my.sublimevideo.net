module InvoicesHelper

  def invoice_dates(invoice)
    if invoice.persisted?
      if invoice.started_at.year == invoice.ended_at.year && invoice.started_at.month == invoice.ended_at.month
        l(invoice.ended_at, :format => :month_fullyear)
      else
        "#{l(invoice.started_at, :format => :month_fullyear)} - #{l(invoice.ended_at, :format => :month_fullyear)}"
      end
    else
      "#{l(invoice.started_at, :format => :date)} to #{l(Time.now, :format => :date)}"
    end
  end

  def invoice_item_dates(invoice_item)
    "#{l(invoice_item.started_at, :format => :minutes_timezone)} - #{l(invoice_item.ended_at, :format => :minutes_timezone)}"
  end

  def charging_status(invoice)
    if invoice.unpaid?
      if invoice.charging_delayed_job.present?
        "Will be charged on #{l(invoice.charging_delayed_job.run_at, :format => :minutes_timezone)}"
      else
        "Not charged yet"
      end
    elsif invoice.paid?
      "Charged on #{l(invoice.paid_at, :format => :minutes_timezone)}"
    elsif invoice.failed?
      "Charging failed on #{l(invoice.failed_at, :format => :minutes_timezone)} with the following error:<br />\"#{invoice.last_error}\"".html_safe
    end
  end

  def invoice_items_grouped_by_site(invoice)
    invoice.invoice_items.group_by { |invoice_item| invoice_item.site }.sort { |a,b| a[0].hostname <=> b[0].hostname }
  end

  def get_plan_invoice_item(invoice_items)
    invoice_items.detect { |invoice_item| invoice_item.type == 'InvoiceItem::Plan' }
  end

  def get_overage_invoice_item(invoice_items)
    invoice_items.detect { |invoice_item| invoice_item.type == 'InvoiceItem::Overage' }
  end

  def get_addons_invoice_items_grouped_by_item(invoice_items)
    invoice_items.select { |invoice_item| invoice_item.type == 'InvoiceItem::Addon' }.group_by { |invoice_item| invoice_item.item }
  end

end
