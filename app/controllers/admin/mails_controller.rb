class Admin::MailsController < Admin::AdminController
  respond_to :js, :html

  before_filter { |controller| require_role?('god') }

  # For MailLog
  has_scope :by_admin_email, :by_template_title, :by_title, :by_date

  # GET /mails
  def index
    params[:by_date]   = 'desc' unless params[:by_date]
    templates_and_logs = !(params[:mail_logs] || params[:mail_templates])
    if params[:mail_logs] || templates_and_logs
      @mail_logs = apply_scopes(MailLog.scoped).page(params[:page])
    end
    if params[:mail_templates] || templates_and_logs
      @mail_templates = apply_scopes(MailTemplate.not_archived).page(params[:page])
      @archived_mail_templates = apply_scopes(MailTemplate.archived).page(params[:page])
    end
  end

  # GET /mails/new
  def new
    _find_mail_template(params[:template_id]) if params[:template_id]
    @mail_log = MailLog.new
  end

  # POST /mails/confirm
  def confirm
    _find_mail_template(params[:mail][:template_id])
  end

  # POST /mails
  def create
    Administration::EmailSender.delay.deliver_and_log(params[:mail].merge(admin_id: current_admin.id))
    redirect_to [:admin, :mails], notice: 'Sending in progress...'
  end

  private

  def _find_mail_template(template_id)
    @mail_template = MailTemplate.find(template_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to [:new, :admin, :mail], alert: 'Please select an email template!'
  end

end
