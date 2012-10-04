require 'spec_helper'

describe Site::AddonPlan do
  describe "Associations" do
    it { should belong_to(:addon).class_name('Site::Addon') }
  end

  describe "Validations" do
    [:addon, :name, :price, :availability].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end

    it { should ensure_inclusion_of(:availability).in_array(%w[hidden beta public custom]) }

    it { should validate_numericality_of(:price) }

  end
end

# == Schema Information
#
# Table name: site_addon_plans
#
#  availability  :string(255)      not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  name          :string(255)      not null
#  price         :integer          not null
#  site_addon_id :integer          not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_site_addon_plans_on_site_addon_id           (site_addon_id)
#  index_site_addon_plans_on_site_addon_id_and_name  (site_addon_id,name) UNIQUE
#

