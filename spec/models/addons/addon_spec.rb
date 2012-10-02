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
    it { should have_many(:componentships) }
    it { should have_many(:components).through(:componentships) }
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

  describe 'Scopes' do
    before do
      @free_beta_addon   = create(:addon, availability: 'beta', category: 'logo', name: 'sublime', price: 0)
      @beta_addon        = create(:addon, availability: 'beta', category: 'logo', name: 'no-logo', price: 999)
      @free_public_addon = create(:addon, availability: 'public', price: 0)
      @public_addon      = create(:addon, availability: 'public', price: 999)
      @custom_addon      = create(:addon, availability: 'custom', price: 999)
    end

    describe '._category' do
      it { described_class._category('logo', @free_public_addon.category).should =~ [@free_beta_addon, @beta_addon, @free_public_addon] }
    end


    describe '._name' do
      it { described_class._name('no-logo', @public_addon.name).should =~ [@beta_addon, @public_addon] }
    end

    describe '.not_beta' do
      it { described_class.not_beta.should =~ [@free_public_addon, @public_addon, @custom_addon] }
    end

    describe '.paid' do
      it { described_class.paid.should =~ [@public_addon, @custom_addon] }
    end
  end

  describe '.get' do
    it { described_class.get('logo', 'no-logo').should eq @beta_addon }
  end

  describe '#beta?' do
    it { build(:addon, availability: 'beta').should be_beta }
    it { build(:addon, availability: 'public').should_not be_beta }
    it { build(:addon, availability: 'custom').should_not be_beta }
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

