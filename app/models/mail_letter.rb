class MailLetter
  extend ActiveModel::Naming
  include ActiveModel::Validations

  validates :template, :admin_id, :criteria, presence: true

  DEV_TEAM_EMAILS = %w[thibaud@jilion.com remy@jilion.com zeno@jilion.com octave@jilion.com]

  def self.deliver_and_log(params)
    mail_letter = new(params)
    mail_letter.deliver_and_log
  end

  def initialize(params)
    @template = MailTemplate.find(params[:template_id])
    @admin    = Admin.find(params[:admin_id])
    @criteria = params[:criteria]
  end

  # ====================
  # = Instance Methods =
  # ====================

  def deliver_and_log
    users = case @criteria
            when 'dev'
              User.where(email: DEV_TEAM_EMAILS)
            when 'trial'
              User.includes(:sites).merge(Site.in_trial).where{ sites.trial_started_at == nil }
            when 'old_trial'
              User.includes(:sites).merge(Site.in_trial).where{ sites.trial_started_at != nil }
            else
              User.send(@criteria)
            end

    users.not_archived.all.uniq.each { |user| self.class.delay.deliver(user.id, @template.id) }

    unless @criteria == 'dev'
      @template.logs.create(admin_id: @admin.id, criteria: @criteria, user_ids: users.map(&:id))
    end
  end

private

  def self.deliver(user_id, template_id)
    MailMailer.delay.send_mail_with_template(user_id, template_id)
  end

end
