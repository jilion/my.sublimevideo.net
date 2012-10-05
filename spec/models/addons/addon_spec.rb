require 'spec_helper'

describe Addons::Addon do

  context "Factory" do
    subject { create(:addon) }

    its(:category)     { should be_present }
    its(:name)         { should be_present }
    its(:title)        { should be_present }
    its(:price)        { should eq 999 }
    its(:availability) { should eq 'public' }

    it { should be_valid }
  end

  describe "Associations" do
    it { should have_many(:addonships) }
    it { should have_many(:sites).through(:addonships) }
  end

  describe "Validations" do
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:availability) }

    it 'validates uniqueness of name scoped by category' do
      create(:addon, category: 'logo', name: 'no-logo')
      addon = build(:addon, category: 'logo', name: 'no-logo')

      addon.should_not be_valid
    end

    it { should allow_value('public').for(:availability) }
    it { should allow_value('beta').for(:availability) }
    it { should allow_value('custom').for(:availability) }
    it { should_not allow_value('fake').for(:availability) }
  end

end

# == Schema Information
#
# Table name: addons
#
#  availability :string(255)      not null
#  category     :string(255)      not null
#  created_at   :datetime         not null
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  price        :integer          not null
#  settings     :hstore
#  title        :string(255)      not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_addons_on_category_and_name  (category,name) UNIQUE
#

