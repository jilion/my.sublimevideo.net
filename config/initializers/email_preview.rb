if Rails.env.development?
  # user         = User.find(user_id)
  # trial_site   = user.sites.in_trial.last
  # site         = user.sites.joins(:invoices).in_paid_plan.group { sites.id }.having { { invoices => (count(id) > 0) } }.last || user.sites.last
  # invoice      = site.invoices.last || Invoice.construct(site: site)
  # transaction  = invoice.transactions.last || Transaction.create(invoices: [invoice])
  # stats_export = StatsExport.create(st: site.token, from: 30.days.ago.midnight.to_i, to: 1.days.ago.midnight.to_i, file: File.new(Rails.root.join('spec/fixtures', 'stats_export.csv')))

  %w[trial_has_started trial_will_expire trial_has_expired].each do |method|
    EmailPreview.register "BillingMailer #{method}", category: :billing do
      user       = User.last
      trial_site = user.sites.create!(plan_id: Plan.trial_plan.id, hostname: 'test.sublimevideo.net')

      BillingMailer.send(method, trial_site.id)
    end
  end

  EmailPreview.register "BillingMailer yearly_plan_will_be_renewed", category: :billing do
    user = User.last
    site = user.sites.create!(plan_id: Plan.yearly_plans.first.id, hostname: 'test.sublimevideo.net')

    BillingMailer.yearly_plan_will_be_renewed(site.id)
  end

  # %w[credit_card_will_expire]
  # %w[transaction_succeeded transaction_failed]
  # %w[too_many_charging_attempts]
end
