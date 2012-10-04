require 'spec_helper'

describe Site::Kit do
  describe "Associations" do
    it { should belong_to :site }
    it { should belong_to(:design).class_name('App::Design') }
  end

  describe "Validations" do
    [:site, :design].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
    it { should allow_mass_assignment_of(:name) }

    [:site, :design, :name].each do |attr|
      it { should validate_presence_of(attr) }
    end
  end
end

# == Schema Information
#
# Table name: site_kits
#
#  app_design_id :integer          not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  name          :string(255)      default("Default"), not null
#  settings      :hstore
#  site_id       :integer          not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_site_kits_on_app_design_id     (app_design_id)
#  index_site_kits_on_site_id           (site_id)
#  index_site_kits_on_site_id_and_name  (site_id,name) UNIQUE
#

