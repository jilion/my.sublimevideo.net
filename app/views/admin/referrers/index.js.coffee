$('#referrers_table_wrap').html "<%= j(render 'referrers') %>"
$('#table_spinner').hide()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
