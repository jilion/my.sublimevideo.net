jQuery('#releases_table_wrap').html "<%= j(render 'releases') %>"
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareSortAndStickyLinks()