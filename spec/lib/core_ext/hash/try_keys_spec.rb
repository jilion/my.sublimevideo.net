require 'fast_spec_helper'

require 'core_ext/hash/try_keys'

describe Hash do

  let(:hash) { { 'x' => { y: 1 } } }

  context 'key is found' do
    it 'returns the correct value' do
      expect(hash.try_keys('x', :y)).to eq 1
    end

    it 'returns the correct value even with a default block' do
      expect(hash.try_keys('x', :y) { 42 }).to eq 1
    end

    it 'returns the correct value even with a default block' do
      expect(hash.try_keys('x')).to eq({ y: 1 })
    end
  end

  context 'key is not found' do
    it 'returns nil if key is not found' do
      expect(hash.try_keys('x', :z)).to be_nil
    end

    it 'returns the given block result if key is not found' do
      expect(hash.try_keys('x', :z) { 42 }).to eq 42
    end
  end

end
