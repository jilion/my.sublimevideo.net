class Admin::MailTemplatesController < AdminController
  respond_to :html

  before_filter { |controller| require_role?('god') }

  # GET /mails/templates/new
  def new
    @mail_template = MailTemplate.new
  end

  # POST /mails/templates
  def create
    @mail_template = MailTemplate.new(params[:mail_template])
    @mail_template.save
    respond_with(@mail_template, location: [:admin, :mails])
  end

  # GET /mails/templates/:id/edit
  def edit
    @mail_template = MailTemplate.find(params[:id])
    respond_with(@mail_template)
  end

  # PUT /mails/templates/:id
  def update
    @mail_template = MailTemplate.find(params[:id])
    @mail_template.update_attributes(params[:mail_template])
    respond_with(@mail_template, location: [:edit,  :admin, @mail_template])
  end

end
