class MailLetter
  extend ActiveModel::Naming
  include ActiveModel::Validations

  validates :template, :admin_id, :criteria, presence: true

  DEV_TEAM_EMAILS = %w[thibaud@jilion.com remy@jilion.com zeno@zeno.name octave@jilion.com andrea@jilion.com]

  def self.deliver_and_log(params)
    mail_letter = new(params)
    mail_letter.deliver_and_log
  end

  def self.deliver(user_id, template_id)
    MailMailer.send_mail_with_template(user_id, template_id)
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
    else
      User.send(@criteria)
    end

    users.not_archived.all.uniq.each { |user| self.class.delay(queue: 'mailer').deliver(user.id, @template.id) }

    unless @criteria == 'dev'
      @template.logs.create(admin_id: @admin.id, criteria: @criteria, user_ids: users.map(&:id))
    end
  end

end
