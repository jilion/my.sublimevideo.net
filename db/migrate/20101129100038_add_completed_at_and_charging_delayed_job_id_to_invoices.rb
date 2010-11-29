class AddCompletedAtAndChargingDelayedJobIdToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :completed_at, :datetime
    add_column :invoices, :charging_delayed_job_id, :integer
  end
  
  def self.down
    remove_column :invoices, :charging_delayed_job_id
    remove_column :invoices, :completed_at
  end
end