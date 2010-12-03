module InvoicesHelper
  
  def invoice_dates(invoice)
    if invoice.persisted?
      if invoice.started_at.year == invoice.ended_at.year && invoice.started_at.month == invoice.ended_at.month
        l(invoice.ended_at, :format => :month_year)
      else
        "#{l(invoice.started_at, :format => :month_year)} - #{l(invoice.ended_at, :format => :month_year)}"
      end
    else
      "#{l(invoice.started_at, :format => :usage_statement)} to #{l(Time.now, :format => :usage_statement)}"
    end
  end
  
  def invoice_item_dates(invoice_item)
    "#{l(invoice_item.started_at, :format => :minutes)} - #{l(invoice_item.ended_at, :format => :minutes)}"
  end
  
  def charging_status(invoice)
    if invoice.unpaid?
      if invoice.charging_delayed_job_id?
        "Will be charged on #{l(invoice.charging_delayed_job.run_at, :format => :minutes)}."
      else
        "Not charged yet."
      end
    elsif invoice.paid?
      "Charged on #{l(invoice.paid_at, :format => :minutes)}."
    elsif invoice.failed?
      "Charging has failed on #{l(invoice.failed_at, :format => :minutes)} with the following error: \"#{invoice.last_error}\"."
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