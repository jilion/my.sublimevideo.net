jQuery('#sites_table_wrap').html "<%= j(render 'sites') %>"
jQuery(document.body).animate({ scrollTop: 0 })
jQuery('a.sort.sticky').each -> new SublimeVideo.UI.SortLink(jQuery(this))
