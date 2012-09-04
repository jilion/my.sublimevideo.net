$('#releases_table_wrap').html "<%= j(render 'releases') %>"
$('#table_spinner').hide()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
