class Addons::Addonship < ActiveRecord::Base

  INACTIVE_STATES = %w[inactive suspended]
  ACTIVE_STATES   = %w[beta trial subscribed sponsored]
  STATES          = INACTIVE_STATES + ACTIVE_STATES

  has_paper_trail

  attr_accessible nil

  # ================
  # = Associations =
  # ================

  belongs_to :site
  belongs_to :addon

  # ===============
  # = Validations =
  # ===============

  validates :site_id, :addon_id, presence: true
  validates :addon_id, uniqueness: { scope: :site_id }
  validates :state, inclusion: STATES

  # =============
  # = Callbacks =
  # =============

  # =================
  # = State Machine =
  # =================

  state_machine initial: :inactive do
    event(:start_beta)  { transition :inactive => :beta }
    event(:start_trial) { transition [:inactive, :beta] => :trial }
    event(:subscribe)   { transition all - [:subscribed] => :subscribed }
    event(:cancel)      { transition all - [:inactive] => :inactive }
    event(:suspend)     { transition :subscribed => :suspended }
    event(:sponsor)     { transition all - [:sponsored] => :sponsored }

    state :subscribed do
      def price
        addon.price
      end
    end

    state :inactive, :beta, :trial, :suspended, :sponsored do
      def price
        0
      end
    end

    before_transition any => :trial do |addonship, transition|
      addonship.trial_started_on = Time.now.utc.midnight unless addonship.trial_started_on?
    end
  end

  # ==========
  # = Scopes =
  # ==========

  scope :in_category,     ->(cat) { includes(:addon).where { addon.category == cat } }
  scope :except_addon_id, ->(excepted_addon_id) { where{ addon_id != excepted_addon_id } }
  scope :out_of_trial,    -> {
    where{ addonships.state == 'trial' }. \
    where{ addonships.trial_started_on != nil }. \
    where{ addonships.trial_started_on < BusinessModel.days_for_trial.days.ago }
  }
  scope :active,         -> { where { state >> ACTIVE_STATES } }
  scope :subscribed,     -> { where { state == 'subscribed' } }
  # scope :paid,           -> { subscribed.includes(:addon).merge(Addons::Addon.paid) }
  scope :addon_not_beta, -> { includes(:addon).merge(Addons::Addon.not_beta) }

  def active?
    %w[beta trial subscribed sponsored].include?(state)
  end

end
# == Schema Information
#
# Table name: addonships
#
#  addon_id         :integer          not null
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  site_id          :integer          not null
#  state            :string(255)      not null
#  trial_started_on :datetime
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addonships_on_addon_id              (addon_id)
#  index_addonships_on_site_id               (site_id)
#  index_addonships_on_site_id_and_addon_id  (site_id,addon_id) UNIQUE
#  index_addonships_on_state                 (state)
#

# == Schema Information
#
# Table name: addonships
#
#  addon_id         :integer          not null
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  site_id          :integer          not null
#  state            :string(255)      not null
#  trial_started_on :datetime
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addonships_on_addon_id              (addon_id)
#  index_addonships_on_site_id_and_addon_id  (site_id,addon_id) UNIQUE
#  index_addonships_on_state                 (state)
#  index_addonships_on_trial_started_on      (trial_started_on)
#

