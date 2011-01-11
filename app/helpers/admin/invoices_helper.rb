module Admin::InvoicesHelper

  def admin_invoices_page_title(invoices)
    pluralized_invoices = pluralize(invoices.total_entries, 'invoice')
    state = if params[:where_user]
      user = User.find(params[:where_user])
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
