class Admin::MailsController < Admin::AdminController
  respond_to :js, :html

  before_filter { |controller| require_role?('god') }

  # For MailLog
  has_scope :by_admin_email
  has_scope :by_template_title
  # For MailTemplate
  has_scope :by_title
  # For both
  has_scope :by_date

  # GET /mails
  def index
    params[:by_date]   = 'desc' unless params[:by_date]
    templates_and_logs = !(params[:mail_logs] || params[:mail_templates])
    if params[:mail_logs] || templates_and_logs
      @mail_logs = apply_scopes(MailLog.scoped).page(params[:page])
    end
    if params[:mail_templates] || templates_and_logs
      @mail_templates = apply_scopes(MailTemplate.scoped).page(params[:page])
    end
  end

  # GET /mails/new
  def new
    @mail_log      = MailLog.new
    @mail_template = MailTemplate.find_by_id(params[:template_id]) || MailTemplate.first
  end

  # POST /mails
  def create
    @mail_letter = MailLetter.new(params[:mail].merge(admin_id: current_admin.id))
    @mail_letter.delay.deliver_and_log

    redirect_to [:admin, :mails], notice: "Sending in progress..."
  end

end
