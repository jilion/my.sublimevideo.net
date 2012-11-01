class Kit < ActiveRecord::Base
  serialize :settings, Hash

  attr_accessible :site, :name, :app_design_id, :identifier, as: :admin

  belongs_to :site
  belongs_to :design, class_name: 'App::Design', foreign_key: 'app_design_id'

  delegate :skin_token, :kind, to: :design

  validates :site, :design, :name, :identifier, presence: true
  validates :name, uniqueness: { scope: :site_id }

  def initialize(*args)
    super
    self.app_design_id ||= App::Design.get('classic').try(:id)
    if site
      self.identifier = (site.kits.size + 1).to_s
      self.name     ||= "My player #{identifier}"
    end
  end
end

# == Schema Information
#
# Table name: kits
#
#  app_design_id :integer          not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  identifier    :string(255)
#  name          :string(255)      not null
#  settings      :text
#  site_id       :integer          not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_kits_on_app_design_id     (app_design_id)
#  index_kits_on_site_id           (site_id)
#  index_kits_on_site_id_and_name  (site_id,name) UNIQUE
#

