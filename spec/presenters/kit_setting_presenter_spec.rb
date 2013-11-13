require 'fast_spec_helper'

require 'presenters/kit_setting_presenter'

describe KitSettingPresenter do
  let(:site)    { Struct.new(:user, :id).new(nil, 1234) }
  let(:kit)     { double(site: double, settings: { a: 'b' }) }
  let(:view)    { double(params: { kit: { settings: { foo: 'bar' } } }) }

  describe '.initialize' do
    context 'kit settings in params' do
      let(:presenter) { described_class.new(kit: double, design: double, view: view, addon_name: 'a') }
      before do
        allow_any_instance_of(described_class).to receive(:load_addon_plan)
      end

      it 'fetch the kit settings from the params' do
        expect(presenter.settings).to eq({ foo: 'bar' })
      end
    end

    context 'kit settings not in params' do
      let(:presenter) { described_class.new(kit: kit, design: double, view: double(params: {}), addon_name: 'a') }
      before do
        allow_any_instance_of(described_class).to receive(:load_addon_plan)
      end

      it 'fetch the kit settings from the kit' do
        expect(kit.settings).to receive(:symbolize_keys) { kit.settings }

        expect(presenter.settings).to eq({ a: 'b' })
      end
    end
  end

end
