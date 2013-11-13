require 'fast_spec_helper'
require 'rails/railtie'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'models/app'
require 'services/loader_generator'
require 'wrappers/campfire_wrapper'
require 'services/app/component_version_manager'

describe App::ComponentVersionManager do
  let(:app_component) { double('App::Component') }
  let(:app_component_version)   { Struct.new(:component_id, :stage, :name, :version).new(1234, 'beta', 'app', '1.0.0') }
  let(:other_component_version) { Struct.new(:component_id, :stage, :name, :version).new(4321, 'beta', 'foo', '1.0.0') }
  let(:service) { described_class.new(app_component_version) }

  describe '#create' do
    before {
      allow(app_component_version).to receive(:save!)
      allow(app_component_version).to receive(:component) { app_component }
      allow(other_component_version).to receive(:save!)
    }

    it 'saves component_version' do
      expect(app_component_version).to receive(:save!)
      service.create
    end

    context 'app component version' do
      it 'delays the update of all dependant sites loaders' do
        expect(LoaderGenerator).to delay(:update_all_dependant_sites, queue: 'my').with(app_component_version.component_id, app_component_version.stage)
        service.create
      end

      it 'delays Campfire message' do
        expect(CampfireWrapper).to delay(:post).with("App player component version 1.0.0 released")
        service.create
      end
    end

    context 'other component version' do
      let(:service) { described_class.new(other_component_version) }

      it 'does not the update of all dependant sites loaders' do
        expect(LoaderGenerator).not_to delay(:update_all_dependant_sites)
        service.create
      end

      it 'does not delay Campfire message' do
        expect(CampfireWrapper).not_to delay(:post)
        service.create
      end
    end
  end

  describe '#destroy' do
    before do
      allow(app_component_version).to receive(:destroy)
      allow(other_component_version).to receive(:destroy)
    end

    it 'saves component_version' do
      expect(app_component_version).to receive(:destroy)
      service.destroy
    end

    it 'delays the update of all dependant sites loaders' do
      expect(LoaderGenerator).to delay(:update_all_dependant_sites).with(app_component_version.component_id, app_component_version.stage)
      service.destroy
    end

    it 'delays Campfire message' do
      expect(CampfireWrapper).to delay(:post).with("App player component version 1.0.0 DELETED!")
      service.destroy
    end
  end
end
