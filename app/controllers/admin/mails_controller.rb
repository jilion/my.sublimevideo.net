class Admin::MailsController < Admin::AdminController
  respond_to :js, :html
  
  # GET /admin/mails
  def index
    @mail_templates = Mail::Template.order(:created_at.desc).all
    @mail_logs = Mail::Log.order(:created_at.desc).all
  end
  
  # GET /admin/mails/new
  def new
    @mail_log = Mail::Log.new
  end
  
  # POST /admin/mails
  def create
    params[:mail_log][:admin_id] = current_admin.id
    respond_to do |format|
      if Mail::Log.delay.deliver_and_save_log(params[:mail_log])
        format.html { redirect_to admin_mails_url, :notice => "Re-sending of confirmations instructions has been delayed." }
      else
        format.html { render :new }
      end
    end
  end
  
end