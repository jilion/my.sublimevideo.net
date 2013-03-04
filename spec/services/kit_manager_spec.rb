require 'fast_spec_helper'
require 'sidekiq'
require 'config/sidekiq'
require 'support/sidekiq_custom_matchers'

require 'services/kit_manager'

Kit = Struct.new(:params) unless defined?(Kit)
ActiveRecord = Class.new unless defined?(ActiveRecord)
ActiveRecord::RecordInvalid = Class.new unless defined?(ActiveRecord::RecordInvalid)
SettingsSanitizer = Class.new unless defined?(SettingsSanitizer)
SettingsGenerator = Class.new unless defined?(SettingsGenerator)

describe KitManager do
  let(:site)               { stub(touch: true) }
  let(:kit)                { stub(design: stub, site: site, site_id: 1) }
  let(:addon_plan)         { stub }
  let(:service)            { described_class.new(kit) }
  let(:sanitized_settings) { stub }
  let(:settings_sanitizer) { stub(sanitize: sanitized_settings) }

  describe "#save" do
    let(:params) { { name: 'My Kit', app_design_id: 42, settings: { "logo" => { "settings" => "value" } } } }
    before do
      Kit.stub(:transaction).and_yield
      SettingsSanitizer.stub(:new) { settings_sanitizer }
      kit.stub(:name=)
      kit.stub(:app_design_id=)
      kit.stub(:settings=)
      kit.stub(:save!)
      Librato.stub(:increment)
    end

    it 'set name' do
      kit.should_receive(:name=).with('My Kit')

      service.save(params)
    end

    it 'set app_design_id' do
      kit.should_receive(:app_design_id=).with(42)

      service.save(params)
    end

    it 'sanitize settings' do
      SettingsSanitizer.should_receive(:new).with(kit, params[:settings]) { settings_sanitizer }
      settings_sanitizer.should_receive(:sanitize) { sanitized_settings }
      kit.should_receive(:settings=).with(sanitized_settings)

      service.save(params)
    end

    it 'saves kit' do
      kit.should_receive(:save!)

      service.save(params)
    end

    it 'touches site settings_updated_at' do
      site.should_receive(:touch).with(:settings_updated_at)

      service.save(params)
    end

    it 'delays the update of all settings types' do
      SettingsGenerator.should delay(:update_all!).with(kit.site_id)

      service.save(params)
    end

    it 'increments metrics with source = "update"' do
      Librato.should_receive(:increment).with('kits.events', source: 'update')

      service.save(params)
    end
  end

end
