require_dependency 'populate/populator'

class EmailsPopulator < Populator

  def execute(user)
    trial_design        = user.billable_items.app_designs.where(state: 'trial').first || user.billable_items.app_designs.first
    trial_addon_plan    = user.billable_items.addon_plans.where(state: 'trial').first || user.billable_items.addon_plans.first
    site                = user.sites.paying.last || user.sites.last
    invoice             = site.invoices.not_paid.last || InvoiceCreator.build(site: site).tap { |s| s.save }.invoice
    transaction         = invoice.transactions.last || Transaction.create!(invoices: [invoice])
    stats_export        = StatsExport.create(site_token: site.token, from: 30.days.ago.midnight.to_i, to: 1.days.ago.midnight.to_i, file: File.new(Rails.root.join('spec/fixtures', 'stats_export.csv')))

    DeviseMailer.confirmation_instructions(user).deliver!
    DeviseMailer.reset_password_instructions(user).deliver!

    UserMailer.welcome(user.id).deliver!
    UserMailer.account_suspended(user.id).deliver!
    UserMailer.account_unsuspended(user.id).deliver!
    UserMailer.account_archived(user.id).deliver!

    BillingMailer.trial_will_expire(trial_design.id).deliver!
    BillingMailer.trial_has_expired(site.id, trial_design.item.class.to_s, trial_design.item_id).deliver!
    BillingMailer.trial_will_expire(trial_addon_plan.id).deliver!
    BillingMailer.trial_has_expired(site.id, trial_addon_plan.item.class.to_s, trial_addon_plan.item_id).deliver!

    BillingMailer.credit_card_will_expire(user.id).deliver!

    BillingMailer.transaction_succeeded(transaction.id).deliver!
    BillingMailer.transaction_failed(transaction.id).deliver!

    StatsExportMailer.export_ready(stats_export).deliver!

    MailMailer.send_mail_with_template(user.id, MailTemplate.last.id).deliver!
  end

end
