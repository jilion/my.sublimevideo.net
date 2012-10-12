class App::Component < ActiveRecord::Base
  attr_accessible :name, :token, as: :admin

  has_many :versions, class_name: 'App::ComponentVersion', foreign_key: 'app_component_id', dependent: :destroy, order: 'version desc'

  scope :app, ->{ where(token: 'e') }

  validates :token, :name, presence: true, uniqueness: true

  def self.app_component
    self.app.first
  end

  def to_param
    token
  end
end

# == Schema Information
#
# Table name: app_components
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  name       :string(255)
#  token      :string(255)
#  updated_at :datetime         not null
#
# Indexes
#
#  index_player_components_on_name   (name) UNIQUE
#  index_player_components_on_token  (token) UNIQUE
#

