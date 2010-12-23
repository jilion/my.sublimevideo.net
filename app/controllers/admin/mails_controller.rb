class Admin::MailsController < Admin::AdminController
  include ActionView::Helpers::TextHelper
  respond_to :js, :html
  
  # For Mail::Log
  has_scope :by_admin_email
  has_scope :by_template_title
  # For Mail::Template
  has_scope :by_title
  # For both
  has_scope :by_date
  
  # GET /admin/mails
  def index
    if params[:mail_logs] || !(params[:mail_logs] || params[:mail_templates])
      @mail_logs = apply_scopes(Mail::Log.scoped).by_date.paginate(:page => params[:page], :per_page => Mail::Log.per_page)
    end
    if params[:mail_templates] || !(params[:mail_logs] || params[:mail_templates])
      @mail_templates = apply_scopes(Mail::Template.scoped).by_date.paginate(:page => params[:page], :per_page => Mail::Template.per_page)
    end
  end
  
  # GET /admin/mails/new
  def new
    @mail_log = Mail::Log.new
  end
  
  # POST /admin/mails
  def create
    @mail_letter = Mail::Letter.new(params[:mail_log].merge(:admin_id => current_admin.id))
    @mail_letter.delay.deliver_and_log
    redirect_to admin_mails_url, :notice => "Sending in progress..."
  end
  
end