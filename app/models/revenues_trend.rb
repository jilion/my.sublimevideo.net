class RevenuesTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :r, type: Hash # revenues hash: { "design" => { "html5" => { 999 } }, "logo" => { "custom" => 999 } }

  def self.json_fields
    [:r]
  end

  def self.determine_last_trend_day
    if self.present?
      self.order_by(d: 1).last.try(:d)
    else
      (BillableItemActivity.order(:created_at).first.created_at).midnight - 1.day
    end
  end

  def self.trend_hash(day)
    hash = {
      d: day.utc,
      r: Hash.new { |h, k| h[k] = Hash.new(0) }
    }

    # logic removed

    hash
  end

  def self._second_key_for_hash(invoice_item)
    case invoice_item.item
    when Design
      'design'
    when AddonPlan
      invoice_item.item.addon_name
    end
  end

end
