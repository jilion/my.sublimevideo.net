require 'spec_helper'

describe BillableEntity do

  class BillableThing < ActiveRecord::Base
    include BillableEntity

    attr_reader :availability, :stable_at, :price

    def initialize(availability = nil, stable_at = nil, price = nil)
      @availability = availability
      @stable_at    = stable_at
      @price        = price
    end
  end

  describe '#not_custom?' do
    it { BillableThing.new('hidden').should     be_not_custom }
    it { BillableThing.new('public').should     be_not_custom }
    it { BillableThing.new('custom').should_not be_not_custom }
  end

  describe '#beta?' do
    it { BillableThing.new.should be_beta }
    it { BillableThing.new(nil, Time.now).should_not be_beta }
  end

  describe '#free?' do
    it { BillableThing.new(nil, nil, 0).should           be_free }
    it { BillableThing.new(nil, nil, 10).should_not      be_free }
    it { BillableThing.new(nil, Time.now, 0).should      be_free }
    it { BillableThing.new(nil, Time.now, 10).should_not be_free }
  end

end