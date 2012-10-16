class Kit < ActiveRecord::Base
  serialize :settings, Hash

  attr_accessible :site, :design, as: :admin
  attr_accessible :name

  belongs_to :site
  belongs_to :design, class_name: 'App::Design', foreign_key: 'app_design_id'

  delegate :skin_token, :kind, to: :design

  validates :site, :design, :name, presence: true
  validates :name, uniqueness: { scope: :site_id }

  before_validation ->(kit) do
    kit.design = App::Design.first unless kit.app_design_id?
  end
end

# == Schema Information
#
# Table name: kits
#
#  app_design_id :integer          not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  name          :string(255)      default("Default"), not null
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

