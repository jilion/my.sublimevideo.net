document.title = document.title.replace /- .+/, "- <%= admin_invoices_page_title(@invoices) %>"
$('#content h2').html "<%= admin_invoices_page_title(@invoices) %>"
$('#invoices_table_wrap').html "<%= j(render 'invoices') %>"
$('#table_spinner').hide()

SublimeVideo.UI.prepareRemoteLinks()
