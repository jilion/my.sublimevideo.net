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
      it { expect(AddonPlan.free).to match_array([@addon_plan7, @addon_plan8, @addon_plan9, @addon_plan10, @addon_plan11, @addon_plan12]) }
    end

    describe '.paid' do
      it { expect(AddonPlan.paid.to_a).to match_array([@addon_plan4, @addon_plan5, @addon_plan6]) }
    end

    describe '.custom' do
      it { expect(AddonPlan.custom).to match_array([@addon_plan3, @addon_plan6, @addon_plan9, @addon_plan12]) }
    end

    describe '.not_custom' do
      it { expect(AddonPlan.not_custom).to match_array([@addon_plan1, @addon_plan2, @addon_plan4, @addon_plan5, @addon_plan7, @addon_plan8, @addon_plan10, @addon_plan11]) }
    end

    describe '.visible' do
      it { expect(AddonPlan.visible).to match_array([@addon_plan1, @addon_plan3, @addon_plan4, @addon_plan6, @addon_plan7, @addon_plan9, @addon_plan10, @addon_plan12]) }
    end
  end

  describe '#free?' do
    it { expect(build(:addon_plan, price: 0)).to                           be_free }
    it { expect(build(:addon_plan, price: 10)).not_to                      be_free }
    it { expect(build(:addon_plan, stable_at: Time.now, price: 0)).to      be_free }
    it { expect(build(:addon_plan, stable_at: Time.now, price: 10)).not_to be_free }
  end

  describe '#not_custom?' do
    it { expect(build(:addon_plan, availability: 'hidden')).to     be_not_custom }
    it { expect(build(:addon_plan, availability: 'public')).to     be_not_custom }
    it { expect(build(:addon_plan, availability: 'custom')).not_to be_not_custom }
  end

  describe '#beta?' do
    it { expect(build(:addon_plan, stable_at: nil)).to be_beta }
    it { expect(build(:addon_plan, stable_at: Time.now)).not_to be_beta }
  end

end
