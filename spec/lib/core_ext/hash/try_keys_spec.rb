require 'fast_spec_helper'

require 'core_ext/hash/try_keys'

describe Hash do

  let(:hash) { { 'x' => { y: 1 } } }

  context 'key is found' do
    it 'returns the correct value' do
      hash.try_keys('x', :y).should eq 1
    end

    it 'returns the correct value even with a default block' do
      hash.try_keys('x', :y) { 42 }.should eq 1
    end

    it 'returns the correct value even with a default block' do
      hash.try_keys('x').should eq({ y: 1 })
    end
  end

  context 'key is not found' do
    it 'returns nil if key is not found' do
      hash.try_keys('x', :z).should be_nil
    end

    it 'returns the given block result if key is not found' do
      hash.try_keys('x', :z) { 42 }.should eq 42
    end
  end

end
