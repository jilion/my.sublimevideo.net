class Addons::Addonship < ActiveRecord::Base

  STATES = %w[beta trial sponsored active inactive suspended]

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

  # =============
  # = Callbacks =
  # =============

  before_save :set_trial_started_on

  # =================
  # = State Machine =
  # =================

  state_machine initial: :trial do
    event(:buy)     { transition [:beta, :trial, :canceled, :suspended] => :paying }
    event(:cancel)  { transition [:beta, :trial, :sponsored, :paying, :suspended] => :canceled }
    event(:suspend) { transition [:paying] => :suspended }
  end

  # ==========
  # = Scopes =
  # ==========

  scope :in_category,     ->(cat) { includes(:addon).where { addon.category == cat } }
  scope :except_addon_id, ->(excepted_addon_id) { where{ addon_id != excepted_addon_id } }

  private

  def set_trial_started_on
    self.trial_started_on = Time.now.utc.midnight if state == 'trial' && !trial_started_on?
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

