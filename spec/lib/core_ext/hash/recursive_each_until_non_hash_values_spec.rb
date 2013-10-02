require 'fast_spec_helper'

require 'core_ext/hash/recursive_each_until_non_hash_values'

describe Hash do

  describe '#recursive_each_until_non_hash_values' do
    let(:hash_1) { { a: 1, b: 2 } }
    let(:hash_2) { { a: { aa: 1 }, b: { bb: 2 } } }
    let(:hash_3) { { a: { aa: { aaa: 1 } }, b: { bb: { bbb: 2 } } } }
    let(:hash_non_symetric) { { 'x' => { 'y' => 5 }, 'z' => 2 } }

    it 'goes recursively at the max depth level' do
      sum = 0
      hash_1.recursive_each_until_non_hash_values do |k, v|
        sum += v
      end

      expect(sum).to eq 3
    end

    it 'goes recursively at the max depth level' do
      sum = 0
      hash_2.recursive_each_until_non_hash_values do |k, v|
        sum += v
      end

      expect(sum).to eq 3
    end

    it 'goes recursively at the max depth level' do
      sum = 0
      hash_3.recursive_each_until_non_hash_values do |k, v|
        sum += v
      end

      expect(sum).to eq 3
    end

    it 'goes recursively at the max depth level' do
      sum = 0
      hash_non_symetric.recursive_each_until_non_hash_values do |k, v|
        sum += v
      end

      expect(sum).to eq 7
    end
  end

end
