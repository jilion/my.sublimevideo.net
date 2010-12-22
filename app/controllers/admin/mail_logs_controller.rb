class Admin::MailLogsController < Admin::AdminController
  respond_to :html
  
  # GET /admin/mails/logs/:id/edit
  def show
    @mail_log = MailLog.find(params[:id])
    respond_with(@mail_log)
  end
  
end