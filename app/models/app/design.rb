class App::Design < ActiveRecord::Base
  AVAILABILITIES = %w[public custom]

  attr_accessible :component, :skin_token, :name, :price, :availability, :public_at, as: :admin

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'
  has_many :billable_items, as: :item

  validates :component, :skin_token, :name, :price, :availability, presence: true
  validates :price, numericality: true
  validates :availability, inclusion: AVAILABILITIES

  scope :paid, -> { where { price > 0 } }

  def self.get(name)
    where(name: name.to_s).first
  end

  def available?(site)
    case availability
    when 'public'
      true
    when 'custom'
      site.app_designs.where(id: id).exists?
    end
  end

  def beta?
    !public_at?
  end

  def free?
    price.zero?
  end

  def title
    I18n.t("app_designs.#{name}")
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
#  public_at        :datetime
#  skin_token       :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_designs_on_name        (name) UNIQUE
#  index_app_designs_on_skin_token  (skin_token) UNIQUE
#

