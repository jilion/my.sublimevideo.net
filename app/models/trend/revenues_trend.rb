# encoding: utf-8
class RevenuesTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :r, type: Hash # design revenue { "design" => { "html5" => { 999 } }, "logo" => { "custom" => 999 } }

  def self.json_fields
    [:r]
  end

  def self.determine_last_trend_day
    if self.present?
      self.order_by(d: 1).last.try(:d)
    else
      (BillableItemActivity.order{ created_at.asc }.first.created_at).midnight - 1.day
    end
  end

  def self.trend_hash(day)
    hash = {
      d: day.to_time,
      r: Hash.new { |h,k| h[k] = Hash.new(0) }
    }

    ::Site.not_archived.find_each do |site|
      invoice_service = InvoiceCreator.build_for_period(day.to_time.all_day, site)

      invoice_service.invoice.invoice_items.each do |invoice_item|
        hash[:r][_second_key_for_hash(invoice_item)][invoice_item.item.name] += invoice_item.amount
      end
    end

    hash
  end

  def self._second_key_for_hash(invoice_item)
    case invoice_item.type
    when 'InvoiceItem::AppDesign'
      'design'
    when 'InvoiceItem::AddonPlan'
      invoice_item.item.addon.name
    end
  end

end
