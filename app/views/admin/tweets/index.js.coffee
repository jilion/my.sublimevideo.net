$('#tweets_table_wrap').html "<%= j(render 'tweets') %>"
$('#table_spinner').hide()
$('#users_title').html "<%= pluralize(@tweets.count, 'Tweet') %>"
$(document.body).scrollTo()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
