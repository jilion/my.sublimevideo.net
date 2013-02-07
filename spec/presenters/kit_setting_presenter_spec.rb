require 'fast_spec_helper'

require File.expand_path('app/presenters/kit_setting_presenter')

describe KitSettingPresenter do
  let(:site)    { Struct.new(:user, :id).new(nil, 1234) }
  let(:kit)     { stub(site: stub, settings: { a: 'b' }) }
  let(:view)    { stub(params: { kit: { settings: { foo: 'bar' } } }) }
  let(:presenter) { described_class.new(view: view) }

  describe '.initialize' do
    context 'kit settings in params' do
      let(:presenter) { described_class.new(kit: stub, design: stub, view: view) }
      before do
        described_class.any_instance.stub(:load_addon_plan)
      end

      it 'fetch the kit settings from the params' do
        presenter.settings.should == { foo: 'bar' }
      end
    end

    context 'kit settings not in params' do
      let(:presenter) { described_class.new(kit: kit, design: stub, view: stub(params: {})) }
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
