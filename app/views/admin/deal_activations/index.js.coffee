$('#deal_activations_table_wrap').html "<%= j(render 'deal_activations') %>"
$('#table_spinner').hide()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
