require 'fast_spec_helper'
require 'active_support/core_ext'

require 'populate/populator'
require 'populate/addon_plan_settings_populator'

App = Class.new unless defined?(App)
AddonPlanSettings = Class.new unless defined?(AddonPlanSettings)

describe AddonPlanSettingsPopulator do
  let(:base_attrs) { { addon_plan: double(addon_name: 'lightbox', name: 'standard'), plugin: double } }
  let(:attrs) { base_attrs.dup }
  let(:populator) { described_class.new(attrs) }

  describe '#execute' do
    context 'template for an addon' do
      context 'without a :suffix' do
        let(:base_attrs) { { addon_plan: double(addon_name: 'video_player', name: 'standard'), plugin: double } }

        it 'creates the record in DB' do
          template = YAML.load_file(described_class::SETTINGS_DIR.join("video_player_template.yml")).symbolize_keys
          expect(AddonPlanSettings).to receive(:create).with(base_attrs.merge(template: template))

          populator.execute
        end
      end

      context 'with a :suffix' do
        before { attrs.merge!(suffix: 'without_close_button') }

        it 'creates the record in DB' do
          template = YAML.load_file(described_class::SETTINGS_DIR.join("lightbox_without_close_button_template.yml")).symbolize_keys
          expect(AddonPlanSettings).to receive(:create).with(base_attrs.merge(template: template))

          populator.execute
        end
      end
    end

    context 'template for an addon plan without a template file' do
      let(:base_attrs) { { addon_plan: double(addon_name: 'foo', name: 'bar'), plugin: double } }

      it 'creates the record in DB and set the templat to {}' do
        expect(AddonPlanSettings).to receive(:create).with(base_attrs.merge(template: {}))

        populator.execute
      end
    end
  end
end
