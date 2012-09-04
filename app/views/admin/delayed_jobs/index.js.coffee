$('#delayed_jobs_table_wrap').html "<%= j(render 'delayed_jobs') %>"
$('#table_spinner').hide()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
