# encoding: utf-8
class BillableItemsTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :be, type: Hash # beta { "design" => { "classic" => 2 }, "logo" => { "custom" => 1 } }
  field :tr, type: Hash # trial { "design" => { "classic" => 2 }, "logo" => { "disabled" => 1 } }
  field :sb, type: Hash # subscribed { "design" => { "classic" => 2 } }
  field :sp, type: Hash # sponsored { "design" => { "classic" => 2 } }
  field :su, type: Hash # suspended { "design" => { "classic" => 2 } }

  def self.json_fields
    [:be, :tr, :sb, :sp, :su]
  end

  def self.create_trends
    self.create(trend_hash(Time.now.utc.midnight))
  end

  def self.trend_hash(day)
    hash = {
      d: day.to_time
    }

    BillableItem::STATES.each do |state|
      first_key = state == 'subscribed' ? 'sb' : state[0,2]
      hash[first_key] = Hash.new { |h,k| h[k] = Hash.new(0) }

      billable_items = BillableItem.select('item_type, item_id, COUNT(item_id) as count').where(state: state).group(:item_type, :item_id)
      billable_items.each do |billable_item|
        second_key = case billable_item.item
        when App::Design
          'design'
        when AddonPlan
          billable_item.item.addon.name
        end
        hash[first_key][second_key][billable_item.item.name] += billable_item.count.to_i
      end
    end
    hash
  end

end
