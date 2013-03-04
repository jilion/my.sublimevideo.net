class InvoiceItemBuilder
  attr_reader :item, :invoice

  def initialize(invoice, item)
    @invoice, @item = invoice, item
  end

  def build_invoice_item(args = {})
    invoice_item = InvoiceItem.new({
      item: item,
      started_at: args[:started_at],
      ended_at: args[:ended_at],
      price: item.price,
      amount: _amount(args[:started_at], args[:ended_at])
    }, without_protection: true)

    invoice.invoice_items << invoice_item unless invoice_item.amount.zero?
  end

  private

  def self._full_days(start_date, end_date)
    ((end_date + 1 - start_date) / _one_day).floor
  end

  def self._one_day
    3600 * 24
  end

  def self._days_in_month(date)
    Time.days_in_month(date.month, date.year)
  end

  def _amount(started_at, ended_at)
    (self.class._full_days(started_at, ended_at) * _price_per_day(started_at)).round
  end

  def _price_per_day(date)
    item.price.to_f / self.class._days_in_month(date)
  end

end
