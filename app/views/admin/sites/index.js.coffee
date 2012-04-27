document.title = document.title.replace /- .+/, "- <%= admin_sites_page_title(@sites) %>"
jQuery('#content h2').html "<%= admin_sites_page_title(@sites) %>"
jQuery('#sites_table_wrap').html "<%= j(render 'sites') %>"
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareSortAndStickyLinks()