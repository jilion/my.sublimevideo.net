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
    if params[:mail_logs] || !(params[:mail_logs] || params[:mail_templates])
      @mail_logs = apply_scopes(MailLog.scoped).by_date.page(params[:page])
    end
    if params[:mail_templates] || !(params[:mail_logs] || params[:mail_templates])
      @mail_templates = apply_scopes(MailTemplate.scoped).by_date.page(params[:page])
    end
  end

  # GET /mails/new
  def new
    @mail_log = MailLog.new
  end

  # POST /mails
  def create
    @mail_letter = MailLetter.new(params[:mail_log].merge(admin_id: current_admin.id))
    @mail_letter.delay.deliver_and_log
    redirect_to [:admin, :mails], notice: "Sending in progress..."
  end

end
