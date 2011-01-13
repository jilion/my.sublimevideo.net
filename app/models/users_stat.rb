class UsersStat
  include Mongoid::Document
  include Mongoid::Timestamps

  field :active_and_billable_count,     :type => Integer, :default => 0
  field :active_and_not_billable_count, :type => Integer, :default => 0
  field :suspended_count,               :type => Integer, :default => 0
  field :archived_count,                :type => Integer, :default => 0

  index :created_at

  # =================
  # = Class Methods =
  # =================

  def self.delay_create_users_stats
    unless Delayed::Job.already_delayed?('%UsersStat%create_users_stats%')
      delay(:run_at => Time.now.utc.change(:min => 0) + 1.hour).create_users_stats # every hour
    end
  end

  def self.create_users_stats
    delay_create_users_stats
    self.create(
      :active_and_billable_count     => User.active_and_billable.count,
      :active_and_not_billable_count => User.active_and_not_billable.count,
      :suspended_count               => User.with_state(:suspended).count,
      :archived_count                => User.with_state(:archived).count
    )
  end

end
