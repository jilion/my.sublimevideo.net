require 'findable_and_cached'

class App::Design < ActiveRecord::Base
  include BillableEntity
  include FindableAndCached

  attr_accessible :component, :skin_token, :name, :price, :availability, :required_stage, :stable_at, as: :admin

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'

  validates :component, :skin_token, :name, :price, :availability, :required_stage, presence: true
  validates :name, uniqueness: true

  after_save :clear_caches

  def available_for_subscription?(site)
    case availability
    when 'public'
      true
    when 'custom'
      site.app_designs.where(id: id).exists?
    end
  end

  def title
    I18n.t("app_designs.#{name}")
  end

  def free_plan
    nil
  end

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
#  required_stage   :string(255)      default("stable"), not null
#  skin_token       :string(255)      not null
#  stable_at        :datetime
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_designs_on_name        (name) UNIQUE
#  index_app_designs_on_skin_token  (skin_token) UNIQUE
#

