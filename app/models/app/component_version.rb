require 'solve'

class App::ComponentVersion < ActiveRecord::Base
  delegate :token, :name, to: :component

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id', touch: true

  acts_as_paranoid
  mount_uploader :zip, App::ComponentVersionUploader

  validates :component, :zip, presence: true
  validates :version, uniqueness: { scope: :app_component_id }

  before_validation ->(component_version) do
    component_version.dependencies ||= {}
  end

  def token=(token)
    self.component = App::Component.where(token: token).first!
  end

  def dependencies=(arg)
    arg = JSON.parse(arg) if arg.is_a?(String)
    write_attribute(:dependencies, arg)
  end

  def to_param
    version_for_url || id
  end

  def version_for_url
    version && version.gsub(/\./, '_')
  end

  def component_id
    app_component_id
  end

  def stage
    Stage.version_stage(version)
  end

  def self.find_by_version!(version_for_url)
    version_string = version_for_url.gsub /_/, '.'
    where(version: version_string).first!
  end

  def solve_version
    @solve_version ||= Solve::Version.new(version)
  end

  def <=>(other)
    solve_version <=> other.solve_version
  end
end

# == Schema Information
#
# Table name: app_component_versions
#
#  app_component_id :integer
#  created_at       :datetime
#  deleted_at       :datetime
#  dependencies     :hstore
#  id               :integer          not null, primary key
#  updated_at       :datetime
#  version          :string(255)
#  zip              :string(255)
#
# Indexes
#
#  index_app_component_versions_on_deleted_at_and_app_component_id  (deleted_at,app_component_id)
#  index_component_versions_on_component_id_and_version             (app_component_id,version) UNIQUE
#

