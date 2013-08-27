class BillingsTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :ne, type: Hash # new sales { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
  field :re, type: Hash # renew sales { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }

  def self.json_fields
    [:ne, :re]
  end

  def self.determine_last_trend_day
    if self.present?
      self.order_by(d: 1).last.try(:d)
    else
      _first_invoice_day - 1.day
    end
  end

  def self.trend_hash(day)
    invoices = Invoice.includes(:invoice_items).paid.paid_between(day.beginning_of_day, day.end_of_day).references(:invoice_items)
    hash = {
      d: day.utc,
      ne: Hash.new { |h, k| h[k] = Hash.new(0) },
      re: Hash.new { |h, k| h[k] = Hash.new(0) }
    }

    invoices.each do |invoice|
      deduction_amount = invoice.balance_deduction_amount
      first_key = invoice.renew? ? :re : :ne

      invoice.invoice_items.order('price DESC').each do |invoice_item|
        nested_keys = _nested_keys(invoice_item)
        amount, deduction_amount = _calculate_amounts(invoice_item, deduction_amount)
        hash[first_key][nested_keys[0]][nested_keys[1]] += amount
      end
    end

    hash
  end

  def self._first_invoice_day
    (Invoice.paid.order(:paid_at).first.try(:paid_at) || 1.day.from_now).midnight
  end

  def self._nested_keys(invoice_item)
    third_key = invoice_item.item.name
    second_key = case invoice_item.item
                 when Design
                   'design'
                 when AddonPlan
                   invoice_item.item.addon_name
                 when Plan
                   third_key = invoice_item.item.cycle[0]
                   invoice_item.item.name
                 end

   [second_key, third_key]
  end

  def self._calculate_amounts(invoice_item, deduction_amount)
    amount = [0, invoice_item.amount - deduction_amount].max
    deduction_amount -= [amount, deduction_amount].min

    [amount, deduction_amount]
  end

end
