class Admin::MailsController < Admin::AdminController
  respond_to :js, :html
  
  # For MailLog
  has_scope :by_admin_email
  has_scope :by_template_title
  # For MailTemplate
  has_scope :by_title
  # For both
  has_scope :by_date
  
  # GET /admin/mails
  def index
    if params[:mail_logs] || !(params[:mail_logs] || params[:mail_templates])
      @mail_logs = apply_scopes(MailLog.by_date).paginate(:page => params[:page], :per_page => MailLog.per_page)
    end
    if params[:mail_templates] || !(params[:mail_logs] || params[:mail_templates])
      @mail_templates = apply_scopes(MailTemplate.by_date).paginate(:page => params[:page], :per_page => MailTemplate.per_page)
    end
  end
  
  # GET /admin/mails/new
  def new
    @mail_log = MailLog.new
  end
  
  # POST /admin/mails
  def create
    @mail_letter = MailLetter.new(params[:mail_log].merge(:admin_id => current_admin.id))
    @mail_letter.delay.deliver_and_log
    redirect_to [:admin, :mails], :notice => "Sending in progress..."
  end
  
end