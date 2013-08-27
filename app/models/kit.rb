class Kit < ActiveRecord::Base
  serialize :settings, Hash

  belongs_to :site
  belongs_to :design

  delegate :skin_token, :skin_mod, to: :design
  delegate :kind, to: :addon

  validates :site, :design, :name, :identifier, presence: true
  validates :identifier, :name, uniqueness: { scope: :site_id }

  def initialize(*args)
    super
    self.design_id ||= Design.get('classic').try(:id)
    self.identifier = (site.kits.size + 1).to_s if site
  end

  def default?
    site.default_kit_id == id
  end

  def to_param
    identifier
  end

  def as_json(options = nil)
    json = super
    json['settings'] = settings.reduce({}) do |hash, (addon_name, setting)|
      hash[Addon.get(addon_name).kind.underscore] = setting
      hash
    end
    json
  end

end

# == Schema Information
#
# Table name: kits
#
#  created_at :datetime         not null
#  design_id  :integer          not null
#  id         :integer          not null, primary key
#  identifier :string(255)
#  name       :string(255)      not null
#  settings   :text
#  site_id    :integer          not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_kits_on_design_id               (design_id)
#  index_kits_on_site_id                 (site_id)
#  index_kits_on_site_id_and_identifier  (site_id,identifier) UNIQUE
#  index_kits_on_site_id_and_name        (site_id,name) UNIQUE
#

