class Admin::Mails::LogsController < Admin::AdminController
  respond_to :html
  
  # GET /admin/mails/logs/1/edit
  def show
    @mail_log = Mail::Log.find(params[:id])
    respond_with(@mail_log)
  end
  
end