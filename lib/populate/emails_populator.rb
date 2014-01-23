class EmailsPopulator < Populator

  def execute(user)
    trial_design        = user.billable_items.designs.state('trial').first || user.billable_items.designs.first
    trial_addon_plan    = user.billable_items.addon_plans.state('trial').first || user.billable_items.addon_plans.first
    site                = user.sites.paying.last || user.sites.last
    invoice             = site.invoices.not_paid.last || InvoiceCreator.build_for_month(1.month.ago, site).tap { |s| s.save }.invoice
    transaction         = invoice.transactions.last || Transaction.new(invoices: [invoice])

    DeviseMailer.confirmation_instructions(user).deliver!
    DeviseMailer.reset_password_instructions(user).deliver!

    UserMailer.welcome(user.id).deliver!
    UserMailer.account_suspended(user.id).deliver!
    UserMailer.account_unsuspended(user.id).deliver!
    UserMailer.account_archived(user.id).deliver!

    MailMailer.send_mail_with_template(user.id, MailTemplate.last.id).deliver!
  end

end
