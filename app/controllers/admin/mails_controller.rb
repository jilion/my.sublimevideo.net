class Admin::MailsController < Admin::AdminController
  include ActionView::Helpers::TextHelper
  respond_to :js, :html
  
  # For Mail::Log
  has_scope :by_admin_email
  has_scope :by_template_title
  # For Mail::Template
  has_scope :by_title
  # For both
  has_scope :by_date, :default => 'desc', :always => true do |controller, scope, value|
    controller.params.keys.any? { |k| k != "by_date" && k =~ /(by_\w+)/ } ? scope : scope.by_date(value)
  end
  
  # GET /admin/mails
  def index
    if params[:mail_logs] || !(params[:mail_logs] || params[:mail_templates])
      @mail_logs      = apply_scopes(Mail::Log).paginate(:page => params[:page], :per_page => Mail::Log.per_page)
    end
    if params[:mail_templates] || !(params[:mail_logs] || params[:mail_templates])
      @mail_templates = apply_scopes(Mail::Template).paginate(:page => params[:page], :per_page => Mail::Template.per_page)
    end
  end
  
  # GET /admin/mails/new
  def new
    @mail_log = Mail::Log.new
  end
  
  # POST /admin/mails
  def create
    @mail_letter = Mail::Letter.new(params[:mail_log].merge(:admin_id => current_admin.id))
    respond_to do |format|
      @mail_log = @mail_letter.deliver_and_log
      if @mail_log.nil?
        format.html { render :new }
      else
        format.html { redirect_to admin_mails_url, :notice => "Mail with template '#{@mail_log.template.title}' will be sent to #{pluralize(@mail_log.user_ids.size, 'user')}!" }
      end
    end
  end
  
end