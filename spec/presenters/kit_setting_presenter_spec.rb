require 'fast_spec_helper'

require 'presenters/kit_setting_presenter'

describe KitSettingPresenter do
  let(:site)    { Struct.new(:user, :id).new(nil, 1234) }
  let(:kit)     { double(site: double, settings: { a: 'b' }) }
  let(:view)    { double(params: { kit: { settings: { foo: 'bar' } } }) }

  describe '.initialize' do
    context 'kit settings not in params' do
      let(:presenter) { described_class.new(kit: kit, design: double, view: double(params: {}), addon_name: 'a') }
      before do
        described_class.any_instance.stub(:load_addon_plan)
      end

      it 'fetch the kit settings from the kit' do
        kit.settings.should_receive(:symbolize_keys) { kit.settings }

        presenter.settings.should == { a: 'b' }
      end
    end
  end

end
