require 'fast_spec_helper'

require 'services/settings_formatter'

describe SettingsFormatter do

  describe '#format' do
    it 'camelcase symbol & string keys recursively' do
      expect(described_class.new(foo_bar: { 'bar_foo' => 'baz' }).format).to eq({
        'fooBar' => { 'barFoo' => 'baz' }
      })
    end
  end

  describe '.format' do
    it 'formats key' do
      service = double('SettingsFormatter')
      expect(described_class).to receive(:new).with(foo_bar: { 'bar_foo' => 'baz' }) { service }
      expect(service).to receive(:format)

      described_class.format(foo_bar: { 'bar_foo' => 'baz' })
    end
  end

end
