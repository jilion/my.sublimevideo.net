class App::Design < ActiveRecord::Base
  AVAILABILITIES = %w[beta public custom]

  attr_accessible :component, :skin_token, :name, :price, :availability, as: :admin

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'

  validates :component, :skin_token, :name, :price, :availability, presence: true
  validates :price, numericality: true
  validates :availability, inclusion: AVAILABILITIES
end

# == Schema Information
#
# Table name: app_designs
#
#  app_component_id :integer          not null
#  availability     :string(255)      not null
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  price            :integer          not null
#  skin_token       :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_designs_on_name        (name) UNIQUE
#  index_app_designs_on_skin_token  (skin_token) UNIQUE
#
