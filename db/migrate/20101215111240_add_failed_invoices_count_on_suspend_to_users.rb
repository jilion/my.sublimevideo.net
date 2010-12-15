class AddFailedInvoicesCountOnSuspendToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :failed_invoices_count_on_suspend, :integer, :default => 0
  end

  def self.down
    remove_column :users, :failed_invoices_count_on_suspend
  end
end