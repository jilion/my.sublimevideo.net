require_dependency 'configurator'

class PublicLaunch
  include Configurator

  config_file 'public_launch.yml', rails_env: false
  config_accessor :beta_transition_started_on

  def self.beta_transition_ended_on
    Time.utc(2011, 04, 16, 12)
  end

  def self.v2_started_on
    Time.utc(2011, 10, 1)
  end

  def self.days_left_before_end_of_beta_transition
    ((beta_transition_ended_on - Time.now.utc) / (3600 * 24)).floor
  end

  def self.hours_left_before_end_of_beta_transition
    ((beta_transition_ended_on - Time.now.utc) / 3600).floor
  end

end
