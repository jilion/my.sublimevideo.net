class TrendsPopulator < Populator

  def execute
    _generate_users_trends
    _generate_sites_trends
    _generate_billable_items_trends
    _generate_billings_trends
    _generate_revenues_trends
  end

  private

  def _generate_users_trends(start_at = 1.year.ago)
    PopulateHelpers.empty_tables(UsersTrend)

    day = start_at.midnight
    hash = { fr: 0, pa: 0, su: 0, ar: 0 }

    while day <= Time.now.utc.midnight
      hash[:d]   = day
      hash[:fr] += rand(100)
      hash[:pa] += rand(25)
      hash[:su] += rand(2)
      hash[:ar] += rand(4)

      UsersTrend.create(hash)

      day += 1.day
    end

    puts "#{UsersTrend.count} days of users trends generated!"
  end

  def _generate_sites_trends(start_at = 1.year.ago)
    PopulateHelpers.empty_tables(SitesTrend)

    day = start_at.midnight
    hash = { fr: { free: 0 }, pa: { plus: { m: 0, y: 0 }, premium: { m: 0, y: 0 }, addons: 0 }, su: 0, ar: 0, al: { st1: 0, st2: 0, st100: 0 } }

    while day <= Time.now.utc.midnight
      hash[:d]          = day
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
      hash[:al][:st1] += rand(30)
      hash[:al][:st2] += rand(20)
      hash[:al][:st100] += rand(2)

      SitesTrend.create(hash)

      day += 1.day
    end

    puts "#{SitesTrend.count} days of sites trends generated!"
  end

  def _generate_billable_items_trends(start_at = Time.utc(2012, 12, 14))
    PopulateHelpers.empty_tables(BillableItemsTrend)

    day = start_at.midnight
    hash = { be: { 'design' => Hash.new(0) }, tr: { 'design' => Hash.new(0) }, sb: { 'design' => Hash.new(0) }, sp: { 'design' => Hash.new(0) }, su: { 'design' => Hash.new(0) } }

    while day <= Time.now.utc.midnight
      hash[:d] = day
      Design.all.each do |design|
        hash[:be]['design'][design.name] += rand(300)
        hash[:tr]['design'][design.name] += rand(400)
        hash[:sb]['design'][design.name] += rand(200)
        hash[:sp]['design'][design.name] += rand(50)
        hash[:su]['design'][design.name] += rand(20)
      end

      AddonPlan.all.each do |addon_plan|
        hash[:be][addon_plan.addon_name] ||= Hash.new(0)
        hash[:tr][addon_plan.addon_name] ||= Hash.new(0)
        hash[:sb][addon_plan.addon_name] ||= Hash.new(0)
        hash[:sp][addon_plan.addon_name] ||= Hash.new(0)
        hash[:su][addon_plan.addon_name] ||= Hash.new(0)
        hash[:be][addon_plan.addon_name][addon_plan.name] += rand(300)
        hash[:tr][addon_plan.addon_name][addon_plan.name] += rand(400)
        hash[:sb][addon_plan.addon_name][addon_plan.name] += rand(200)
        hash[:sp][addon_plan.addon_name][addon_plan.name] += rand(50)
        hash[:su][addon_plan.addon_name][addon_plan.name] += rand(20)
      end

      BillableItemsTrend.create(hash)

      day += 1.day
    end

    puts "#{BillableItemsTrend.count} days of billable items trends generated!"
  end

  def _generate_billings_trends
    PopulateHelpers.empty_tables(BillingsTrend)

    BillingsTrend.create_trends

    puts "#{BillingsTrend.count} days of billings trends generated!"
  end

  def _generate_revenues_trends
    PopulateHelpers.empty_tables(RevenuesTrend)

    RevenuesTrend.create_trends

    puts "#{RevenuesTrend.count} days of revenues trends generated!"
  end

end
