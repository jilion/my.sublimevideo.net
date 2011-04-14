class PublicLaunch < Settingslogic
  source "#{Rails.root}/config/public_launch.yml"

  def self.beta_transition_ended_on
    Time.utc(2011, 04, 16, 12)
  end

  def self.days_left_before_end_of_beta_transition
    ((beta_transition_ended_on - Time.now.utc) / (3600 * 24)).floor
  end

  def self.hours_left_before_end_of_beta_transition
    ((beta_transition_ended_on - Time.now.utc) / 3600).floor
  end

end
