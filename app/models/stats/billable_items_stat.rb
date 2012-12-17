module Stats
  class BillableItemsStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'billable_items_stats'

    field :d,  type: DateTime # Day
    field :be, type: Hash     # beta { "design" => { "classic" => 2 }, "logo" => { "custom" => 1 } }
    field :tr, type: Hash     # trial { "design" => { "classic" => 2 }, "logo" => { "disabled" => 1 } }
    field :sb, type: Hash     # subscribed { "design" => { "classic" => 2 } }
    field :sp, type: Hash     # sponsored { "design" => { "classic" => 2 } }
    field :su, type: Hash     # suspended { "design" => { "classic" => 2 } }

    index d: 1

    # send time as id for backbonejs model
    def as_json(options = nil)
      json = super
      json['id'] = d.to_i
      json
    end

    # =================
    # = Class Methods =
    # =================

    class << self

      def json(from = nil, to = nil)
        json_stats = if from.present?
          between(d: from..(to || Time.now.utc.midnight))
        else
          scoped
        end

        json_stats.order_by(d: 1).to_json(only: [:be, :tr, :sb, :sp, :su])
      end

      def create_stats
        self.create(billable_items_hash(Time.now.utc.midnight))
      end

      def billable_items_hash(day)
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

  end
end
