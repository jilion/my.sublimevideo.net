jQuery('#referrers_table_wrap').html "<%= j(render 'referrers') %>"
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })
jQuery('a.sort.sticky').each -> new SublimeVideo.UI.SortLink(jQuery(this))
