class BillableItem < ActiveRecord::Base
  INACTIVE_STATES = %w[suspended] unless defined? INACTIVE_STATES
  ACTIVE_STATES   = %w[subscribed sponsored] unless defined? ACTIVE_STATES
  STATES          = INACTIVE_STATES + ACTIVE_STATES unless defined? STATES

  has_paper_trail

  attr_accessible :item, :site, :state, as: :admin

  belongs_to :site
  belongs_to :item, polymorphic: true
  has_many :components, through: :item

  validates :item, :site, :state, presence: true
  validates :item_id, uniqueness: { scope: [:item_type, :site_id] }
  validates :state, inclusion: STATES

  # =================
  # = State Machine =
  # =================

  state_machine do
    # event(:start_beta)  { transition :inactive => :beta }
    # event(:start_trial) { transition [:inactive, :beta] => :trial }
    event(:subscribe)   { transition all - [:subscribed] => :subscribed }
    event(:suspend)     { transition :subscribed => :suspended }
    event(:sponsor)     { transition all - [:sponsored] => :sponsored }

    state :subscribed do
      def price
        addon.price
      end
    end

    # before_transition any => :trial do |billable_item, transition|
    #   billable_item.trial_started_on = Time.now.utc.midnight unless billable_item.trial_started_on?
    # end

    after_transition do |billable_item, transition|
      BillableItemActivity.create(item: billable_item.item, state: billable_item.state)
    end
  end

  # ==========
  # = Scopes =
  # ==========

  scope :except_addon_ids, ->(excepted_addon_ids) { where{ addon_id << excepted_addon_ids } }
  scope :out_of_trial,     -> {
    where{ billable_items.state == 'trial' }#. \
    # where{ billable_items.trial_started_on != nil }. \
    # where{ billable_items.trial_started_on < BusinessModel.days_for_trial.days.ago }
  }
  scope :active,     -> { where { state >> ACTIVE_STATES } }
  scope :subscribed, -> { where(state: 'subscribed') }
  scope :paid,       -> do
    where{
      ((item_type == 'App::Design') & (item_id >> App::Design.where{ price > 0 }.pluck(:id))) |
      ((item_type == 'AddonPlan') & (item_id >> AddonPlan.where{ price > 0 }.pluck(:id)))
    }
  end

  def active?
    ACTIVE_STATES.include?(state)
  end

end

# == Schema Information
#
# Table name: billable_items
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  item_id    :integer          not null
#  item_type  :string(255)      not null
#  site_id    :integer          not null
#  state      :string(255)      not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_billable_items_on_item_type_and_item_id              (item_type,item_id)
#  index_billable_items_on_item_type_and_item_id_and_site_id  (item_type,item_id,site_id) UNIQUE
#  index_billable_items_on_site_id                            (site_id)
#

