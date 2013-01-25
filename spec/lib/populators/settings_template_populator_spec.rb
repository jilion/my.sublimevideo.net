require 'fast_spec_helper'

require File.expand_path('lib/populate/settings_template_populator')

App = Class.new unless defined?(App)
App::SettingsTemplate = Class.new unless defined?(App::SettingsTemplate)

describe SettingsTemplatePopulator do

  let(:base_attrs) { { addon_plan: stub(addon: stub(name: 'lightbox'), name: 'standard'), plugin: stub } }
  let(:attrs) { base_attrs.dup }
  let(:populator) { described_class.new(attrs) }

  describe '#execute' do
    context 'template for an addon' do
      context 'without a :suffix' do
        let(:base_attrs) { { addon_plan: stub(addon: stub(name: 'video_player'), name: 'standard'), plugin: stub } }

        it 'creates the record in DB' do
          template = YAML.load_file(described_class::SETTINGS_TEMPLATES_DIR.join("video_player_template.yml")).symbolize_keys
          App::SettingsTemplate.should_receive(:create).with(base_attrs.merge(template: template), without_protection: true)

          populator.execute
        end
      end

      context 'with a :suffix' do
        before { attrs.merge!(suffix: 'without_close_button') }

        it 'creates the record in DB' do
          template = YAML.load_file(described_class::SETTINGS_TEMPLATES_DIR.join("lightbox_without_close_button_template.yml")).symbolize_keys
          App::SettingsTemplate.should_receive(:create).with(base_attrs.merge(template: template), without_protection: true)

          populator.execute
        end
      end
    end

    context 'template for an addon plan without a template file' do
      let(:base_attrs) { { addon_plan: stub(addon: stub(name: 'foo'), name: 'bar'), plugin: stub } }

      it 'creates the record in DB and set the templat to {}' do
        App::SettingsTemplate.should_receive(:create).with(base_attrs.merge(template: {}), without_protection: true)

        populator.execute
      end
    end
  end

end
