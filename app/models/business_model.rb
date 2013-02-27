require 'configurator'

class BusinessModel
  include Configurator

  config_file 'business_model.yml', rails_env: false
  config_accessor :new_trial_date, :days_for_trial_old, :days_for_trial_new, :days_before_trial_end_old, :days_before_trial_end_new

  def self.days_for_trial(billable_item_activity = nil)
    if billable_item_activity && billable_item_activity.created_at < self.new_trial_date
      self.days_for_trial_old
    else
      self.days_for_trial_new
    end
  end

  def self.days_before_trial_end(billable_item_activity = nil)
    if billable_item_activity && billable_item_activity.created_at < self.new_trial_date
      self.days_before_trial_end_old
    else
      self.days_before_trial_end_new
    end
  end
end
