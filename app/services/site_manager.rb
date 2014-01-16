require 'rank_setter'
require 'loader_generator'
require 'settings_generator'
require 'addons_subscriber'

class SiteManager
  attr_reader :site

  DEFAULT_DOMAIN = 'please-edit.me'
  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost'

  def initialize(site)
    @site = site
  end

  def create
    @addons_subscriber = AddonsSubscriber.new(site)
    transaction_with_graceful_fail do
      site.hostname      = DEFAULT_DOMAIN if site.hostname.blank?
      site.dev_hostnames = DEFAULT_DEV_DOMAINS if site.dev_hostnames.blank?
      site.save!
      _create_default_kit!
      _set_default_billable_items
      touch_timestamps(%w[loaders settings])
      site.save!
      delay_jobs(:rank_update)
      _increment_librato('create')
    end
  end

  def update(attributes)
    transaction_with_graceful_fail do
      site.attributes = attributes
      touch_timestamps('settings')
      site.save!
      delay_jobs(:settings_update)
      _increment_librato('update')
    end
  end

  def touch_timestamps(types)
    Array(types).each do |type|
      site.send("#{type}_updated_at=", Time.now.utc)
    end
  end

  def delay_jobs(*jobs)
    LoaderGenerator.delay(queue: 'my').update_all_stages!(site.id) if jobs.include?(:loader_update)
    SettingsGenerator.delay(queue: 'my').update_all!(site.id) if jobs.include?(:settings_update)
    RankSetter.delay(queue: 'my-low').set_ranks(site.id) if jobs.include?(:rank_update)
  end

  def transaction_with_graceful_fail
    Site.transaction do
      yield
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def _create_default_kit!
    site.kits.create!(name: 'Default player')
    site.default_kit = site.kits.first
  end

  def _free_designs_subscriptions_hash
    {
      classic: Design.get('classic').id,
      light: Design.get('light').id,
      flat: Design.get('flat').id
    }
  end

  def _free_addon_plans_subscriptions_hash
    AddonPlan.free_addon_plans.reduce({}) do |hash, addon_plan|
      hash[addon_plan.addon_name.to_sym] = addon_plan.id
      hash
    end
  end

  def _set_default_billable_items
    @addons_subscriber.update_billable_items(_free_designs_subscriptions_hash, _free_addon_plans_subscriptions_hash)
  end

  def _increment_librato(event)
    Librato.increment 'sites.events', source: event
  end

end
