require 'spec_helper'

describe BillableEntity do

  describe '#not_custom?' do
    it { build(:addon_plan, availability: 'hidden').should     be_not_custom }
    it { build(:addon_plan, availability: 'public').should     be_not_custom }
    it { build(:addon_plan, availability: 'custom').should_not be_not_custom }
  end

  describe '#beta?' do
    it { build(:addon_plan, stable_at: nil).should be_beta }
    it { build(:addon_plan, stable_at: Time.now).should_not be_beta }
  end

  describe '#free?' do
    it { build(:addon_plan, price: 0).should                           be_free }
    it { build(:addon_plan, price: 10).should_not                      be_free }
    it { build(:addon_plan, stable_at: Time.now, price: 0).should      be_free }
    it { build(:addon_plan, stable_at: Time.now, price: 10).should_not be_free }
  end

end