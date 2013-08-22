require 'spec_helper'

describe BillableEntity do

  describe 'Scopes' do
    before do
      @addon_plan1  = create(:addon_plan, availability: 'public', price: 999, stable_at: nil)
      @addon_plan2  = create(:addon_plan, availability: 'hidden', price: 999, stable_at: nil)
      @addon_plan3  = create(:addon_plan, availability: 'custom', price: 999, stable_at: nil)
      @addon_plan4  = create(:addon_plan, availability: 'public', price: 999, stable_at: Time.now)
      @addon_plan5  = create(:addon_plan, availability: 'hidden', price: 999, stable_at: Time.now)
      @addon_plan6  = create(:addon_plan, availability: 'custom', price: 999, stable_at: Time.now)
      @addon_plan7  = create(:addon_plan, availability: 'public', price: 0, stable_at: Time.now)
      @addon_plan8  = create(:addon_plan, availability: 'hidden', price: 0, stable_at: Time.now)
      @addon_plan9  = create(:addon_plan, availability: 'custom', price: 0, stable_at: Time.now)
      @addon_plan10 = create(:addon_plan, availability: 'public', price: 0, stable_at: nil)
      @addon_plan11 = create(:addon_plan, availability: 'hidden', price: 0, stable_at: nil)
      @addon_plan12 = create(:addon_plan, availability: 'custom', price: 0, stable_at: nil)
    end

    describe '.free' do
      it { AddonPlan.free.should =~ [@addon_plan7, @addon_plan8, @addon_plan9, @addon_plan10, @addon_plan11, @addon_plan12] }
    end

    describe '.paid' do
      it { AddonPlan.paid.to_a.should =~ [@addon_plan4, @addon_plan5, @addon_plan6] }
    end

    describe '.custom' do
      it { AddonPlan.custom.should =~ [@addon_plan3, @addon_plan6, @addon_plan9, @addon_plan12] }
    end

    describe '.not_custom' do
      it { AddonPlan.not_custom.should =~ [@addon_plan1, @addon_plan2, @addon_plan4, @addon_plan5, @addon_plan7, @addon_plan8, @addon_plan10, @addon_plan11] }
    end

    describe '.visible' do
      it { AddonPlan.visible.should =~ [@addon_plan1, @addon_plan3, @addon_plan4, @addon_plan6, @addon_plan7, @addon_plan9, @addon_plan10, @addon_plan12] }
    end
  end

  describe '#free?' do
    it { build(:addon_plan, price: 0).should                           be_free }
    it { build(:addon_plan, price: 10).should_not                      be_free }
    it { build(:addon_plan, stable_at: Time.now, price: 0).should      be_free }
    it { build(:addon_plan, stable_at: Time.now, price: 10).should_not be_free }
  end

  describe '#not_custom?' do
    it { build(:addon_plan, availability: 'hidden').should     be_not_custom }
    it { build(:addon_plan, availability: 'public').should     be_not_custom }
    it { build(:addon_plan, availability: 'custom').should_not be_not_custom }
  end

  describe '#beta?' do
    it { build(:addon_plan, stable_at: nil).should be_beta }
    it { build(:addon_plan, stable_at: Time.now).should_not be_beta }
  end

end
