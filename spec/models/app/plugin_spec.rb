require 'spec_helper'

describe App::Plugin do
  describe "Associations" do
    it { should belong_to(:addon).class_name('Site::Addon') }
    it { should belong_to(:design).class_name('App::Design') }
    it { should belong_to(:component).class_name('App::Component') }
  end

  describe "Validations" do
    [:addon, :design, :component, :token].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
  end
end

# == Schema Information
#
# Table name: app_plugins
#
#  app_component_id :integer          not null
#  app_design_id    :integer
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  site_addon_id    :integer          not null
#  token            :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_plugins_on_app_design_id                    (app_design_id)
#  index_app_plugins_on_app_design_id_and_site_addon_id  (app_design_id,site_addon_id)
#

