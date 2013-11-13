require 'fast_spec_helper'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'services/kit_manager'

Kit = Struct.new(:params) unless defined?(Kit)
ActiveRecord = Class.new unless defined?(ActiveRecord)
ActiveRecord::RecordInvalid = Class.new unless defined?(ActiveRecord::RecordInvalid)
SettingsSanitizer = Class.new unless defined?(SettingsSanitizer)
SettingsGenerator = Class.new unless defined?(SettingsGenerator)

describe KitManager do
  let(:site)               { double(touch: true) }
  let(:kit)                { double(design: double, site: site, site_id: 1) }
  let(:addon_plan)         { double }
  let(:service)            { described_class.new(kit) }
  let(:sanitized_settings) { double }
  let(:settings_sanitizer) { double(sanitize: sanitized_settings) }

  describe "#save" do
    let(:params) { { name: 'My Kit', design_id: 42, settings: { "logo" => { "settings" => "value" } } } }
    before do
      allow(Kit).to receive(:transaction).and_yield
      allow(SettingsSanitizer).to receive(:new) { settings_sanitizer }
      allow(kit).to receive(:name=)
      allow(kit).to receive(:design_id=)
      allow(kit).to receive(:settings=)
      allow(kit).to receive(:save!)
      allow(Librato).to receive(:increment)
    end

    it 'set name' do
      expect(kit).to receive(:name=).with('My Kit')

      service.save(params)
    end

    it 'set design_id' do
      expect(kit).to receive(:design_id=).with(42)

      service.save(params)
    end

    it 'sanitize settings' do
      expect(SettingsSanitizer).to receive(:new).with(kit, params[:settings]) { settings_sanitizer }
      expect(settings_sanitizer).to receive(:sanitize) { sanitized_settings }
      expect(kit).to receive(:settings=).with(sanitized_settings)

      service.save(params)
    end

    it 'saves kit' do
      expect(kit).to receive(:save!)

      service.save(params)
    end

    it 'touches site settings_updated_at' do
      expect(site).to receive(:touch).with(:settings_updated_at)

      service.save(params)
    end

    it 'delays the update of all settings types' do
      expect(SettingsGenerator).to delay(:update_all!).with(kit.site_id)

      service.save(params)
    end

    it 'increments metrics with source = "update"' do
      expect(Librato).to receive(:increment).with('kits.events', source: 'update')

      service.save(params)
    end
  end

end
