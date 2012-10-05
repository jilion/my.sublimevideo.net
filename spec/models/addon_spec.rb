require 'spec_helper'

describe Addon do
  describe 'Associations' do
    it { should have_many(:plans).class_name('AddonPlan') }
    it { should have_many(:plugins).class_name('App::Plugin') }
    it { should have_many(:components).through(:plugins) }
  end

  describe 'Validations' do
    [:name, :design_dependent, :context].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
  end

  context 'Factory' do
    subject { create(:addon) }

    its(:name)    { should be_present }
    its(:context) { should eq [] }

    it { should be_valid }
  end

  describe 'Scopes' do
    before do
      @logo_addon  = create(:addon, name: 'logo')
      @stats_addon = create(:addon, name: 'stats')
    end

    describe '._name' do
      it { described_class._name('logo').should =~ [@logo_addon] }
    end
  end

  describe '.get' do
    it { described_class.get('logo').should eq @logo_addon }
  end

end

# == Schema Information
#
# Table name: addons
#
#  context          :text             not null
#  created_at       :datetime         not null
#  design_dependent :boolean          not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

