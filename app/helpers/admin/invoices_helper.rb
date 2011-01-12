module Admin::InvoicesHelper

  def admin_invoices_page_title(invoices)
    pluralized_invoices = pluralize(invoices.total_entries, 'invoice')
    state = if params[:user_id]
      user = User.find(params[:user_id])
      " for user #{user.full_name.titleize}" if user
    elsif params[:paid]
      " paid"
    elsif params[:failed]
      " failed"
    else
      ""
    end
    "#{pluralized_invoices.humanize}#{state}"
  end

end
