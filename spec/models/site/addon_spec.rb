require 'spec_helper'

describe Site::Addon do
  describe "Validations" do
    [:name, :design_dependent].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
  end
end

# == Schema Information
#
# Table name: site_addons
#
#  created_at       :datetime         not null
#  design_dependent :boolean          not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_site_addons_on_name  (name) UNIQUE
#

