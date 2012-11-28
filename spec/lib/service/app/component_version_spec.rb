require 'fast_spec_helper'
require 'rails/railtie'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('app/models/app')
require File.expand_path('lib/service/app/component_version')

describe Service::App::ComponentVersion do
  let(:component_version) { Struct.new(:component_id, :stage, :name, :version).new(1234, 'beta', 'app', '1.0.0') }
  let(:service)           { described_class.new(component_version) }

  describe '#create' do
    before { component_version.stub(:save!) }

    it 'saves component_version' do
      component_version.should_receive(:save!)
      service.create
    end

    it 'delays the update of all dependant sites loaders' do
      Service::Loader.should delay(:update_all_dependant_sites).with(component_version.component_id, component_version.stage)
      service.create
    end

    it 'delays Campfire message' do
      CampfireWrapper.should delay(:post).with("App player component version 1.0.0 released")
      service.create
    end
  end

  describe '#destroy' do
    before { component_version.stub(:destroy) }

    it 'saves component_version' do
      component_version.should_receive(:destroy)
      service.destroy
    end

    it 'delays the update of all dependant sites loaders' do
      Service::Loader.should delay(:update_all_dependant_sites).with(component_version.component_id, component_version.stage)
      service.destroy
    end

    it 'delays Campfire message' do
      CampfireWrapper.should delay(:post).with("App player component version 1.0.0 DELETED!")
      service.destroy
    end
  end
end
