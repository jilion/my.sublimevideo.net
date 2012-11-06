require 'fast_spec_helper'
require 'rails/railtie'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('app/models/app')
require File.expand_path('lib/service/app/component_version')

describe Service::App::ComponentVersion do
  let(:component_version) { Struct.new(:id).new(1234) }
  let(:service)           { described_class.new(component_version) }

  describe '#create' do
    before do
      component_version.stub(:save!)
    end

    it 'saves component_version' do
      component_version.should_receive(:save!)
      service.create
    end

    it 'delays the update of all dependant sites loaders' do
      Service::Loader.should delay(:update_all_dependant_sites).with(component_version.id)
      service.create
    end
  end
end
