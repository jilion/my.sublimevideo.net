class Admin::Mails::TemplatesController < Admin::AdminController
  respond_to :html
  
  # GET /admin/mails/templates/1/edit
  def edit
    @mail_template = Mail::Template.find(params[:id])
    respond_with(@mail_template)
  end
  
  # PUT /admin/mails/templates/1
  def update
    @mail_template = Mail::Template.find(params[:id])
    respond_with(@mail_template) do |format|
      if @mail_template.update_attributes(params[:mail_template])
        format.html { redirect_to edit_admin_mail_template_url(@mail_template) }
      else
        format.html { render :edit }
      end
    end
  end
  
end