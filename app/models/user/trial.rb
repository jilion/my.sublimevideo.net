# == Schema Information
#
# Table name: users
#
#  trial_ended_at                        :datetime
#  trial_usage_information_email_sent_at :datetime
#  trial_usage_warning_email_sent_at     :datetime
#

module User::Trial
  
  def self.delay_supervise_users(interval = 15.minutes)
    unless Delayed::Job.already_delayed?('%supervise_users%')
      delay(:priority => 5, :run_at => interval.from_now).supervise_users
    end
  end
  
  def self.supervise_users
    delay_supervise_users
    User.in_trial.includes(:invoices, :sites, :videos).each do |user|
      case user.trial_usage_percentage
      when 0..(usage_information_percentage-1)
        # do nothing
      when usage_information_percentage..(usage_warning_percentage-1)
        user.deliver_usage_information_email unless user.credit_card?
      when usage_warning_percentage..99
        user.deliver_usage_warning_email unless user.credit_card?
      else
        user.end_trial
      end
    end
  end
  
  def self.method_missing(name)
    yml[name.to_sym]
  end
  
  # ===================================
  # = User instance methods extension =
  # ===================================
  
  def trial?
    trial_ended_at.nil?
  end
  
  def trial_warning?
    trial_loader_hits_percentage > trial_player_hits_percentage && trial_loader_hits_percentage >= User::Trial.usage_warning_percentage
  end
  
  def trial_loader_hits
    # TODO TEST (wait for Video Invoice)
    hits  = Invoice.current(self).sites.loader_hits
    hits += self.invoices.sum { |i| i.sites.loader_hits } unless self.invoices_count.zero?
    hits
  end
  
  def trial_player_hits
    # TODO TEST (wait for Video Invoice)
    hits  = Invoice.current(self).sites.player_hits
    hits += self.invoices.sum { |i| i.sites.player_hits } unless self.invoices_count.zero?
    hits
  end
  
  def free_hits_left
    User::Trial.free_player_hits - trial_player_hits
  end
  
  def trial_loader_hits_percentage
    ((trial_loader_hits / User::Trial.free_loader_hits.to_f) * 100).to_i
  end
  def trial_player_hits_percentage
    ((trial_player_hits / User::Trial.free_player_hits.to_f) * 100).to_i
  end
  
  def trial_usage_percentage(active = true)
    [trial_loader_hits_percentage, trial_player_hits_percentage].send(active ? 'max' : 'min')
  end
  
  def deliver_usage_information_email
    unless trial_usage_information_email_sent_at.present?
      transaction do
        touch(:trial_usage_information_email_sent_at)
        TrialMailer.usage_information(self).deliver!
      end
    end
  end
  
  def deliver_usage_warning_email
    unless trial_usage_warning_email_sent_at.present?
      transaction do
        touch(:trial_usage_warning_email_sent_at)
        TrialMailer.usage_warning(self).deliver!
      end
    end
  end
  
  def end_trial
    transaction do
      touch(:trial_ended_at)
      unless credit_card?
        suspend!
        UserMailer.account_suspended(self, :trial_ended).deliver!
      end
    end
  end
  
private
  
  def self.yml
    config_path = Rails.root.join('config', 'trial.yml')
    @yml ||= YAML::load_file(config_path).to_options
  rescue
    raise StandardError, "Trial config file '#{config_path}' doesn't exist."
  end
  
end