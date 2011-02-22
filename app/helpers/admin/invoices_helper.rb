module Admin::InvoicesHelper

  def admin_invoices_page_title(invoices)
    pluralized_invoices = pluralize(invoices.total_count, 'invoice')
    state = if params[:user_id]
      user = User.find(params[:user_id])
      " for user #{user.full_name.titleize}" if user
    elsif params[:paid]
      " paid"
    elsif params[:failed]
      " failed"
    elsif params[:search].present?
      " that contains '#{params[:search]}'"
    else
      ""
    end
    "#{pluralized_invoices.titleize}#{state}"
  end

end
