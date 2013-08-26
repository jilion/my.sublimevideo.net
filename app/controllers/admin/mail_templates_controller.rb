class Admin::MailTemplatesController < Admin::AdminController
  respond_to :html

  before_filter { |controller| require_role?('god') }
  before_filter :_set_user, only: [:edit, :preview]
  before_filter :_set_mail_template, only: [:edit, :update, :preview]

  # GET /mails/templates/new
  def new
    @mail_template = MailTemplate.new
  end

  # POST /mails/templates
  def create
    @mail_template = MailTemplate.new(_mail_template_params)
    @mail_template.save
    respond_with(@mail_template, location: [:admin, :mails])
  end

  # GET /mails/templates/:id/edit
  def edit
    respond_with(@mail_template)
  end

  # PUT /mails/templates/:id
  def update
    @mail_template.update(_mail_template_params)
    respond_with(@mail_template, location: [:edit,  :admin, @mail_template])
  end

  # GET /mails/templates/:id/preview
  def preview
    render layout: 'mailer', text: Liquid::Template.parse(@mail_template.body).render('user' => @user)
  end

  private

  def _set_user
    @user = User.first
  end

  def _set_mail_template
    @mail_template = MailTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to [:new, :admin, :mail], alert: 'Please select an email template!'
  end

  def _mail_template_params
    params.require(:mail_template).permit!
  end

end
