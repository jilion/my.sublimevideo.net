class AddTrialStartedAtAndBadgedToSitesAndSupportLevelToPlansAndBalanceToUsersAndBalanceDeductionAmountToInvoices < ActiveRecord::Migration
  def change
    add_column :sites, :trial_started_at, :datetime
    add_column :sites, :badged, :boolean
    add_column :plans, :support_level, :integer, default: 0
    add_column :users, :balance, :integer, default: 0
    add_column :invoices, :balance_deduction_amount, :integer, default: 0
  end
end