class Admin::MailTemplatesController < Admin::AdminController
  respond_to :html

  before_filter { |controller| require_role?('god') }
  before_filter :_find_mail_template, only: [:edit, :update, :preview]

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
    respond_with(@mail_template)
  end

  # PUT /mails/templates/:id
  def update
    @mail_template.update_attributes(params[:mail_template])
    respond_with(@mail_template, location: [:edit,  :admin, @mail_template])
  end

  # GET /mails/templates/:id/preview
  def preview
    @user = User.first
    render layout: 'mailer', text: Liquid::Template.parse(@mail_template.body).render("user" => @user)
  end

  private

  def _find_mail_template
    @mail_template = MailTemplate.find_by_id(params[:id])
  end

end
