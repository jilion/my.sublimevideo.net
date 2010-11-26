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
  
end