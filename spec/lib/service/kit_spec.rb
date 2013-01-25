require 'fast_spec_helper'
require 'rails/railtie'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('lib/service/kit')
require File.expand_path('lib/service/site')

Kit = Struct.new(:params) unless defined?(Kit)
ActiveRecord = Class.new unless defined?(ActiveRecord)
ActiveRecord::RecordInvalid = Class.new unless defined?(ActiveRecord::RecordInvalid)

describe Service::Kit do
  let(:new_site)       { stub(touch: true, new_record?: true) }
  let(:persisted_site) { stub(touch: true, new_record?: false) }
  let(:kit)            { stub(design: stub, site: new_site, site_id: 1) }
  let(:addon_plan)     { stub }
  let(:service)        { described_class.new(kit) }
  let(:sanitized_settings) { stub }
  let(:settings_sanitizer_service) { stub(sanitize: sanitized_settings) }

  describe "#save" do
    let(:params) { { name: 'My Kit', app_design_id: 42, settings: { "logo" => { "settings" => "value" } } } }
    before do
      ::Kit.stub(:transaction).and_yield
      Service::SettingsSanitizer.stub(:new) { settings_sanitizer_service }
      kit.stub(:name=)
      kit.stub(:app_design_id=)
      kit.stub(:settings=)
      kit.stub(:save!)
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
      Service::SettingsSanitizer.should_receive(:new).with(kit, params[:settings]) { settings_sanitizer_service }
      settings_sanitizer_service.should_receive(:sanitize) { sanitized_settings }
      kit.should_receive(:settings=).with(sanitized_settings)

      service.save(params)
    end

    it 'saves kit' do
      kit.should_receive(:save!)

      service.save(params)
    end

    it 'touches site settings_updated_at' do
      new_site.should_receive(:touch).with(:settings_updated_at)

      service.save(params)
    end

    it 'delays the update of all settings types' do
      Service::Settings.should delay(:update_all_types!).with(kit.site_id)

      service.save(params)
    end

    it 'increments metrics with source = "create"' do
      Librato.should_receive(:increment).with('kits.events', source: 'create')

      service.save(params)
    end

    context 'persisted kit' do
      let(:kit)     { stub(design: stub, site: persisted_site, site_id: 1) }
      let(:service) { described_class.new(kit) }

      it 'increments metrics with source = "update"' do
        Librato.should_receive(:increment).with('kits.events', source: 'update')

        service.save(params)
      end
    end
  end

end
