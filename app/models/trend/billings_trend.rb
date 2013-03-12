# encoding: utf-8
class BillingsTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :ne, type: Hash    # new sales { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
  field :re, type: Hash    # renew sales { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }

  def self.json_fields
    [:ne, :re]
  end

  def self.determine_last_trend_day
    if self.present?
      self.order_by(d: 1).last.try(:d)
    else
      (Invoice.paid.order{ paid_at.asc }.first.try(:paid_at) || 1.day.from_now).midnight - 1.day
    end
  end

  def self.trend_hash(day)
    invoices = Invoice.includes(:invoice_items).paid.between(paid_at: day.beginning_of_day..day.end_of_day)
    hash = {
      d: day.to_time,
      ne: Hash.new { |h,k| h[k] = Hash.new(0) },
      re: Hash.new { |h,k| h[k] = Hash.new(0) }
    }

    invoices.each do |invoice|
      deduction_amount = invoice.balance_deduction_amount
      first_key = invoice.renew? ? :re : :ne

      invoice.invoice_items.order('price DESC').each do |invoice_item|
        third_key = invoice_item.item.name
        second_key = case invoice_item.type
                     when 'InvoiceItem::AppDesign'
                       'design'
                     when 'InvoiceItem::AddonPlan'
                       invoice_item.item.addon.name
                     when 'InvoiceItem::Plan'
                       third_key = invoice_item.item.cycle[0]
                       invoice_item.item.name
                     end
        amount = [0, invoice_item.amount - deduction_amount].max
        deduction_amount -= [amount, deduction_amount].min
        hash[first_key][second_key][third_key] += amount
      end
    end

    hash
  end

end
