require 'fast_spec_helper'
require 'rails/railtie'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('app/models/app')
require File.expand_path('lib/service/app/component_version')

describe Service::App::ComponentVersion do
  let(:app_component_version)   { Struct.new(:component_id, :stage, :name, :version).new(1234, 'beta', 'app', '1.0.0') }
  let(:other_component_version) { Struct.new(:component_id, :stage, :name, :version).new(4321, 'beta', 'foo', '1.0.0') }
  let(:service) { described_class.new(app_component_version) }

  describe '#create' do
    before do
      app_component_version.stub(:save!)
      other_component_version.stub(:save!)
    end

    it 'saves component_version' do
      app_component_version.should_receive(:save!)
      service.create
    end

    it 'delays the update of all dependant sites loaders' do
      Service::Loader.should delay(:update_all_dependant_sites).with(app_component_version.component_id, app_component_version.stage)
      service.create
    end

    context 'app component version' do
      it 'delays Campfire message' do
        CampfireWrapper.should delay(:post).with("App player component version 1.0.0 released")
        service.create
      end
    end

    context 'other component version' do
      let(:service) { described_class.new(other_component_version) }

      it 'do not delay Campfire message' do
        CampfireWrapper.should_not delay(:post)
        service.create
      end
    end
  end

  describe '#destroy' do
    before do
      app_component_version.stub(:destroy)
      other_component_version.stub(:destroy)
    end

    it 'saves component_version' do
      app_component_version.should_receive(:destroy)
      service.destroy
    end

    it 'delays the update of all dependant sites loaders' do
      Service::Loader.should delay(:update_all_dependant_sites).with(app_component_version.component_id, app_component_version.stage)
      service.destroy
    end

    context 'app component version' do
      it 'delays Campfire message' do
        CampfireWrapper.should delay(:post).with("App player component version 1.0.0 DELETED!")
        service.destroy
      end
    end

    context 'other component version' do
      let(:service) { described_class.new(other_component_version) }

      it 'do not delay Campfire message' do
        CampfireWrapper.should_not delay(:post)
        service.destroy
      end
    end
  end
end
