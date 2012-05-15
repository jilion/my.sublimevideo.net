class MailLetter
  extend ActiveModel::Naming

  DEV_TEAM_EMAILS = ["thibaud@jilion.com", "remy@jilion.com", "zeno@jilion.com", "octave@jilion.com"]

  def initialize(params)
    @template, @admin_id, @criteria = MailTemplate.find(params[:template_id]), params[:admin_id], params[:criteria]
  end

  # ====================
  # = Instance Methods =
  # ====================

  def deliver_and_log
    return nil if @template.blank? || @admin_id.blank? || @criteria.blank?

    users = case @criteria
            when 'dev'
              User.where(email: DEV_TEAM_EMAILS)
            else
              User.send(@criteria)
            end

    users.all.uniq.each { |user| self.class.delay.deliver(user.id, @template) }

    unless @criteria == 'dev'
      @template.logs.create(admin_id: @admin_id, criteria: @criteria, user_ids: users.map(&:id))
    end
  end

private

  def self.deliver(user_id, template)
    user = User.find(user_id)
    MailMailer.send_mail_with_template(user, template).deliver
  end

end
