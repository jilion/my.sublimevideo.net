require 'fast_spec_helper'
require File.expand_path('lib/services/sites/manager')

Site = Struct.new(:params) unless defined?(Site)

describe Services::Sites::Manager do
  let(:user)              { stub(sites: []) }
  let(:site)              { Struct.new(:user, :id).new(nil, 1234) }
  let(:manager)           { described_class.new(site) }
  let(:addonship_manager) { stub.as_null_object }
  let(:usage_manager)     { stub }
  let(:delayed_method)    { stub }

  describe '.build_site' do
    it 'instantiate a new Services::Sites::Manager and returns it' do
      user.sites.should_receive(:new)

      described_class.build_site(user: user).should be_a(described_class)
    end
  end

  describe '#save' do
    before do
      Site.should_receive(:transaction).and_yield
      Services::Sites::Addonship.stub(:new) { addonship_manager }
      Services::Sites::Rank.stub(:delay) { delayed_method }
      Services::Sites::Usage.stub(:new) { usage_manager }
      usage_manager.stub(:update_last_30_days_video_views_counters)
      delayed_method.stub(:set_ranks)
    end

    context 'site is valid' do
      before do
        site.should_receive(:save) { true }
      end

      it 'adds default add-ons to site after creation' do
        Services::Sites::Addonship.should_receive(:new) { addonship_manager }
        addonship_manager.should_receive(:update_addonships!).with(logo: 'sublime', support: 'standard')

        manager.save
      end

      it 'delays the calculation of google and alexa ranks' do
        Services::Sites::Rank.should_receive(:delay) { delayed_method }
        delayed_method.should_receive(:set_ranks).with(site.id)

        manager.save
      end

      # it 'updates the last 30 days views counter' do
      #   Services::Sites::Usage.should_receive(:new).with(site) { usage_manager }
      #   usage_manager.should_receive(:update_last_30_days_video_views_counters)

      #   manager.save
      # end
    end

    context 'site is not valid' do
      before do
        site.should_receive(:save) { false }
      end

      it 'create a new site and save it to the database' do
        manager.save.should be_false
      end

      it 'doesnt add default add-ons to site after creation' do
        Services::Sites::Addonship.should_not_receive(:new)

        manager.save
      end
    end

  end

end
