jQuery('#deal_activations_table_wrap').html "<%= j(render 'deal_activations') %>"
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareSortAndStickyLinks()