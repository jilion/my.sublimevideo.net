$('#tailor_made_player_requests_table_wrap').html "<%= j(render 'tailor_made_player_requests') %>"
$('#table_spinner').hide()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
