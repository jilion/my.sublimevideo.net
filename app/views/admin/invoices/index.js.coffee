jQuery('#invoices_table_wrap').html "<%= j(render 'invoices') %>"
jQuery('#table_spinner').hide()
<% if params[:search] %>
jQuery('#invoices_title').html "<%= admin_invoices_page_title(@invoices) %>"
<% end %>