class UsersStat
  include Mongoid::Document
  include Mongoid::Timestamps

  field :states_count, :type => Hash

  index :created_at

  # ==========
  # = Scopes =
  # ==========

  scope :between, lambda { |start_date, end_date| where(:created_at => { "$gte" => start_date, "$lt" => end_date }) }

  # =================
  # = Class Methods =
  # =================

  # Recurring task
  def self.delay_create_users_stats
    unless Delayed::Job.already_delayed?('%UsersStat%create_users_stats%')
      delay(:run_at => Time.now.utc.tomorrow.midnight).create_users_stats # every day
    end
  end

  def self.create_users_stats(timestamp=Time.now.utc)
    delay_create_users_stats
    self.create(:states_count => {
      :active_and_billable_count     => User.active_and_billable.select("DISTINCT(users.id)").where(:created_at.gte => timestamp.midnight, :created_at.lte => timestamp.end_of_day).count,
      :active_and_not_billable_count => User.active_and_not_billable.where(:created_at.gte => timestamp.midnight, :created_at.lte => timestamp.end_of_day).count,
      :suspended_count               => User.with_state(:suspended).where(:created_at.gte => timestamp.midnight, :created_at.lte => timestamp.end_of_day).count,
      :archived_count                => User.with_state(:archived).where(:created_at.gte => timestamp.midnight, :created_at.lte => timestamp.end_of_day).count
    })
  end

end
