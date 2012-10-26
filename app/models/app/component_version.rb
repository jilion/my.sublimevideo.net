require 'solve'

class App::ComponentVersion < ActiveRecord::Base
  serialize :dependencies, ActiveRecord::Coders::Hstore
  delegate :token, :name, to: :component

  attr_accessible :component, :token, :dependencies, :version, :zip, as: :admin

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'

  mount_uploader :zip, App::ComponentVersionUploader

  validates :component, :zip, presence: true
  validates :version, uniqueness: { scope: :app_component_id }

  def token=(token)
    self.component = App::Component.find_by_token!(token)
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

