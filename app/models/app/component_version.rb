require_dependency 'semantic_versioning'

class App::ComponentVersion < ActiveRecord::Base
  include SemanticVersioning

  attr_accessible :component, :token, :dependencies, :version, :zip, as: :admin

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'

  delegate :token, :name, to: :component

  mount_uploader :zip, App::ComponentVersionUploader

  validates :component, :zip, presence: true
  validates :version, uniqueness: { scope: :app_component_id }

  def token=(token)
    self.component = App::Component.find_by_token!(token)
  end

  def to_param
    version_for_url
  end

  def version_for_url
    version.gsub /\./, '_'
  end

  def self.find_by_version!(version_for_url)
    version_string = version_for_url.gsub /_/, '.'
    where(version: version_string).first!
  end
end

# == Schema Information
#
# Table name: app_component_versions
#
#  app_component_id :integer
#  created_at       :datetime         not null
#  dependencies     :hstore
#  id               :integer          not null, primary key
#  updated_at       :datetime         not null
#  version          :string(255)
#  zip              :string(255)
#
# Indexes
#
#  index_component_versions_on_component_id_and_version  (app_component_id,version) UNIQUE
#

