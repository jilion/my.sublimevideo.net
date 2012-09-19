require 'spec_helper'
require File.expand_path('lib/player/component_updater')

describe Player::ComponentUpdater do
  let(:delayed_job) { mock('delayed_job') }
  before { Player::Loader.stub(:delay) { delayed_job } }

  # describe ".update" do
  #   context "with the 'app' component" do
  #     let(:component) { Player::Component.create(
  #       name: 'app',
  #       token: 'e'
  #     )}

  #     it "updates 1 loader if one version tag change" do
  #       delayed_job.should_receive(:update!).with('alpha', '2.0.0')
  #       component.should_receive(:save)
  #       Player::ComponentUpdater.update(component, 'version_tags' => {
  #         'alpha' => '2.0.0'
  #       })
  #     end

  #     it "updates 2 loaders if two version tags change" do
  #       delayed_job.should_receive(:update!).with('alpha', '2.0.0')
  #       delayed_job.should_receive(:update!).with('beta', '2.0.0')
  #       component.should_receive(:save)
  #       Player::ComponentUpdater.update(component, 'version_tags' => {
  #         'alpha' => '2.0.0',
  #         'beta'  => '2.0.0'
  #       })
  #     end
  #   end

  #   context "with another component" do
  #     let(:component) { Player::Component.create(
  #       name: 'subtitle',
  #       token: 'bA',
  #       version_tags: {
  #         'alpha'  => '2.0.0-alpha',
  #         'beta'   => '2.0.0-alpha',
  #         'stable' => '1.5.3'
  #       }
  #     )}

  #     it "updates the component normally" do
  #       new_version_tags = { 'version_tags' => { 'alpha' => '2.0.0' } }
  #       delayed_job.should_not_receive(:update!)
  #       component.should_receive(:update_attributes).with(new_version_tags)
  #       Player::ComponentUpdater.update(component, new_version_tags)
  #     end
  #   end
  # end

end
