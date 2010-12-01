class AddSuspendingDelayedJobIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :suspending_delayed_job_id, :integer
  end

  def self.down
    remove_column :users, :suspending_delayed_job_id
  end
end