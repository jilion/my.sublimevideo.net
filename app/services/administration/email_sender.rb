module Administration
  class EmailSender

    DEV_TEAM_EMAILS = %w[thibaud@jilion.com remy@jilion.com zeno@zeno.name octave@jilion.com andrea@jilion.com]
    attr_reader :template, :admin, :criteria

    def initialize(args = {})
      @template = MailTemplate.not_archived.find(args[:template_id])
      @admin    = Admin.find(args[:admin_id])
      @criteria = args[:criteria]
    end

    def self.deliver_and_log(args)
      new(args).deliver_and_log
    end

    def deliver_and_log
      users = _users_scope.not_archived.uniq

      _deliver(users)
      _log(users)
    end

    private

    def _deliver(users)
      users.each do |user|
        MailMailer.delay(queue: 'my').send_mail_with_template(user.id, template.id)
      end
    end

    def _log(users)
      unless criteria == 'dev'
        template.logs.create(admin_id: admin.id, criteria: criteria, user_ids: users.map(&:id))
      end
    end

    def _users_scope
      case criteria
      when 'dev'
        User.where(email: DEV_TEAM_EMAILS)
      else
        eval("User.#{criteria}")
      end
    end

  end
end
