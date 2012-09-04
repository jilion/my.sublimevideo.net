document.title = document.title.replace /- .+/, "- <%= admin_sites_page_title(@sites) %>"
$('#content h2').html "<%= admin_sites_page_title(@sites) %>"
$('#sites_table_wrap').html "<%= j(render 'sites') %>"
$('#table_spinner').hide()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
