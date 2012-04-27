document.title = document.title.replace /- .+/, "- <%= admin_invoices_page_title(@invoices) %>"
jQuery('#content h2').html "<%= admin_invoices_page_title(@invoices) %>"
jQuery('#invoices_table_wrap').html "<%= j(render 'invoices') %>"
jQuery('#table_spinner').hide()

SublimeVideo.UI.prepareSortAndStickyLinks()