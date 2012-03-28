class Admin::MailLogsController < Admin::AdminController
  respond_to :html

  before_filter { |controller| require_role?('god') }

  # GET /mails/logs/:id/edit
  def show
    @mail_log = MailLog.find(params[:id])
    respond_with(@mail_log)
  end

end
