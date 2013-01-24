require_dependency 'populate/populator'
require_dependency 'populate/populate_helpers'

class TrendsPopulator < Populator

  def execute
    generate_users_trends
    generate_sites_trends
    generate_billable_items_trends
    generate_sales_trends
  end

  private

  def generate_users_trends(start_at = 2.years.ago)
    PopulateHelpers.empty_tables(Stats::UsersStat)

    day = start_at.midnight
    hash = { fr: 0, pa: 0, su: 0, ar: 0 }

    while day <= Time.now.utc.midnight
      hash[:d]   = day
      hash[:fr] += rand(100)
      hash[:pa] += rand(25)
      hash[:su] += rand(2)
      hash[:ar] += rand(4)

      Stats::UsersStat.create(hash)

      day += 1.day
    end

    puts "#{Stats::UsersStat.count} days of users trends generated!"
  end

  def generate_sites_trends(start_at = 2.years.ago)
    PopulateHelpers.empty_tables(Stats::SitesStat)

    day = start_at.midnight
    hash = { fr: { free: 0 }, pa: { plus: { m: 0, y: 0 }, premium: { m: 0, y: 0 }, addons: 0 }, su: 0, ar: 0 }

    while day <= Time.now.utc.midnight
      hash[:d]   = day
      hash[:fr][:free] += rand(50)

      if day >= Time.utc(2012, 10, 23)
        hash[:pa][:addons]      += rand(12)
      else
        hash[:pa][:plus][:m]    += rand(7)
        hash[:pa][:plus][:y]    += rand(3)
        hash[:pa][:premium][:m] += rand(4)
        hash[:pa][:premium][:y] += rand(2)
      end
      hash[:su] += rand(3)
      hash[:ar] += rand(6)

      Stats::SitesStat.create(hash)

      day += 1.day
    end

    puts "#{Stats::SitesStat.count} days of sites trends generated!"
  end

  def generate_billable_items_trends(start_at = 2.years.ago)
    PopulateHelpers.empty_tables(Stats::BillableItemsStat)

    day = start_at.midnight
    hash = { be: { 'design' => Hash.new(0) }, tr: { 'design' => Hash.new(0) }, sb: { 'design' => Hash.new(0) }, sp: { 'design' => Hash.new(0) }, su: { 'design' => Hash.new(0) } }

    while day <= Time.now.utc.midnight
      hash[:d] = day
      App::Design.all.each do |design|
        hash[:be]['design'][design.name] += rand(300)
        hash[:tr]['design'][design.name] += rand(400)
        hash[:sb]['design'][design.name] += rand(200)
        hash[:sp]['design'][design.name] += rand(50)
        hash[:su]['design'][design.name] += rand(20)
      end

      AddonPlan.all.each do |addon_plan|
        hash[:be][addon_plan.addon.name] ||= Hash.new(0)
        hash[:tr][addon_plan.addon.name] ||= Hash.new(0)
        hash[:sb][addon_plan.addon.name] ||= Hash.new(0)
        hash[:sp][addon_plan.addon.name] ||= Hash.new(0)
        hash[:su][addon_plan.addon.name] ||= Hash.new(0)

        hash[:be][addon_plan.addon.name][addon_plan.name] += rand(300)
        hash[:tr][addon_plan.addon.name][addon_plan.name] += rand(400)
        hash[:sb][addon_plan.addon.name][addon_plan.name] += rand(200)
        hash[:sp][addon_plan.addon.name][addon_plan.name] += rand(50)
        hash[:su][addon_plan.addon.name][addon_plan.name] += rand(20)
      end

      Stats::BillableItemsStat.create(hash)

      day += 1.day
    end

    puts "#{Stats::BillableItemsStat.count} days of billable items trends generated!"
  end

  def generate_sales_trends
    PopulateHelpers.empty_tables(Stats::SalesStat)

    Stats::SalesStat.create_stats

    puts "#{Stats::SalesStat.count} days of sales trends generated!"
  end

end
