module Admin::InvoicesHelper

  def admin_invoices_page_title(invoices)
    pluralized_invoices = pluralize(invoices.total_count, 'invoice')
    state = if params[:user_id]
      user = User.find(params[:user_id])
      " for user #{user.full_name.titleize}" if user
    elsif state = %w[paid open waiting refunded failed].detect { |state| params.key?(state) }
      " #{state}"
    elsif params[:search].present?
      " matching '#{params[:search]}'"
    else
      ""
    end
    "#{pluralized_invoices.titleize}#{state}"
  end

end
