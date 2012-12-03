require 'spec_helper'

describe App::Plugin do
  describe "Associations" do
    it { should belong_to(:addon) }
    it { should belong_to(:design).class_name('App::Design') }
    it { should belong_to(:component).class_name('App::Component') }
    it { should have_many(:sites).through(:addon) }
  end

  describe "Validations" do
    [:addon, :design, :component, :token, :name].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
  end

  it { build(:app_plugin, design: nil).should be_valid }

  describe '.get' do
    before do
      @app_plugin = create(:app_plugin, name: 'foo')
    end

    it { described_class.get('foo').should eq @app_plugin }
  end

end

# == Schema Information
#
# Table name: app_plugins
#
#  addon_id         :integer          not null
#  app_component_id :integer          not null
#  app_design_id    :integer
#  condition        :text
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  token            :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_plugins_on_app_design_id               (app_design_id)
#  index_app_plugins_on_app_design_id_and_addon_id  (app_design_id,addon_id)
#

