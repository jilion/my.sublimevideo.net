class Admin::MailTemplatesController < Admin::AdminController
  respond_to :html
  
  # GET /admin/mails/templates/new
  def new
    @mail_template = MailTemplate.new
  end
  
  # POST /admin/mails/templates
  def create
    @mail_template = MailTemplate.new(params[:mail_template])
    @mail_template.save
    respond_with(@mail_template, :location => [:admin, :mails])
  end
  
  # GET /admin/mails/templates/1/edit
  def edit
    @mail_template = MailTemplate.find(params[:id])
    respond_with(@mail_template)
  end
  
  # PUT /admin/mails/templates/1
  def update
    @mail_template = MailTemplate.find(params[:id])
    @mail_template.update_attributes(params[:mail_template])
    respond_with(@mail_template, :location => [:edit,  :admin, @mail_template])
  end
  
end