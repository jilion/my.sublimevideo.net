# == Schema Information
#
# Table name: users
#
#  trial_ended_at                        :datetime
#  trial_usage_information_email_sent_at :datetime
#  trial_usage_warning_email_sent_at     :datetime
#

module User::Trial
  
  def self.delay_supervise_users(minutes = 15.minutes)
    unless supervise_users_already_delayed?(minutes)
      delay(:priority => 5, :run_at => minutes.from_now).supervise_users
    end
  end
  
  def self.supervise_users
    User.in_trial.includes(:invoices, :sites, :videos).each do |user|
      case user.trial_usage_percentage
      when 0..49
        # do nothing
      when 50..89
        user.deliver_usage_information_email unless user.credit_card?
      when 90..99
        user.deliver_usage_warning_email unless user.credit_card?
      else
        user.end_trial
      end
    end
    delay_supervise_users
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
  
  def trial_loader_hits_percentage
    ((trial_loader_hits / User::Trial.free_loader_hits.to_f) * 100).to_i
  end
  def trial_player_hits_percentage
    ((trial_player_hits / User::Trial.free_player_hits.to_f) * 100).to_i
  end
  
  def trial_usage_percentage
    trial_loader_hits_percentage > trial_player_hits_percentage ? trial_loader_hits_percentage : trial_player_hits_percentage
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
  
  def self.supervise_users_already_delayed?(minutes)
    Delayed::Job.where(
      :handler =~ '%supervise_users%',
      :run_at > (minutes - 7.seconds).from_now
    ).present?
  end
  
end