require 'findable_and_cached'

class Design < BillableEntity
  include FindableAndCached

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'

  validates :component, :skin_token, :name, :price, :availability, :required_stage, presence: true
  validates :name, uniqueness: true

  after_save :clear_caches

  def available_for_subscription?(site)
    case availability
    when 'public'
      true
    when 'custom'
      site.designs.where(id: id).exists?
    end
  end

  def title
    I18n.t("designs.#{name}")
  end

  def free_plan
    nil
  end

end

# == Schema Information
#
# Table name: designs
#
#  app_component_id :integer          not null
#  availability     :string(255)      not null
#  created_at       :datetime
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  price            :integer          not null
#  required_stage   :string(255)      default("stable"), not null
#  skin_mod         :string(255)
#  skin_token       :string(255)      not null
#  stable_at        :datetime
#  updated_at       :datetime
#
# Indexes
#
#  index_designs_on_name        (name) UNIQUE
#  index_designs_on_skin_token  (skin_token) UNIQUE
#

