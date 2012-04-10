jQuery('#sites_table_wrap').html "<%= j(render 'sites') %>"
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareSortAndStickyLinks()
MySublimeVideo.UI.prepareEmbedCodePopups()
MySublimeVideo.UI.prepareSitesStatus()