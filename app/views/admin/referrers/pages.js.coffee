jQuery('#referrers_table_wrap').html "<%= j(render 'pages') %>"
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
