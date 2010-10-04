class Admin::MailsController < Admin::AdminController
  respond_to :js, :html
  
  # GET /admin/mails
  def index
    @mail_templates = Mail::Template.order(:created_at.desc).all
    # @mail_logs = MailLog.scoped
  end
  
end