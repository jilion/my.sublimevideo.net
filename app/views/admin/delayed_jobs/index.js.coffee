jQuery('#delayed_jobs_table_wrap').html "<%= j(render 'delayed_jobs') %>"
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareSortAndStickyLinks()