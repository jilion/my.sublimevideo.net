class PublicLaunch < Settingslogic
  source "#{Rails.root}/config/public_launch.yml"

  def self.days_left_before_end_of_beta_transition
    (beta_transition_ended_on - Date.today).to_i
  end

end
