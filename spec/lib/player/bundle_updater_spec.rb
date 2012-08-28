require 'spec_helper'
require File.expand_path('lib/player/bundle_updater')

describe Player::BundleUpdater do
  let(:delayed_job) { mock('delayed_job') }
  before { Player::Loader.stub(:delay) { delayed_job } }

  describe ".update" do
    context "with the 'app' bundle" do
      let(:bundle) { Player::Bundle.create(
        name: 'app',
        token: 'e',
        version_tags: {
          'alpha'  => '2.0.0-alpha',
          'beta'   => '2.0.0-alpha',
          'stable' => '1.5.3'
        }
      )}

      it "updates 1 loader if one version tag change" do
        delayed_job.should_receive(:update!).with('alpha', '2.0.0')
        bundle.should_receive(:save)
        Player::BundleUpdater.update(bundle, 'version_tags' => {
          'alpha' => '2.0.0'
        })
      end

      it "updates 2 loaders if two version tags change" do
        delayed_job.should_receive(:update!).with('alpha', '2.0.0')
        delayed_job.should_receive(:update!).with('beta', '2.0.0')
        bundle.should_receive(:save)
        Player::BundleUpdater.update(bundle, 'version_tags' => {
          'alpha' => '2.0.0',
          'beta'  => '2.0.0'
        })
      end
    end

    context "with another bundle" do
      let(:bundle) { Player::Bundle.create(
        name: 'subtitle',
        token: 'bA',
        version_tags: {
          'alpha'  => '2.0.0-alpha',
          'beta'   => '2.0.0-alpha',
          'stable' => '1.5.3'
        }
      )}

      it "updates the bundle normally" do
        new_version_tags = { 'version_tags' => { 'alpha' => '2.0.0' } }
        delayed_job.should_not_receive(:update!)
        bundle.should_receive(:update_attributes).with(new_version_tags)
        Player::BundleUpdater.update(bundle, new_version_tags)
      end
    end
  end

end
