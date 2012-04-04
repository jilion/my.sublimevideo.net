jQuery('#admins_table_wrap').html "<%= j(render 'admins') %>"
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })
jQuery('a.sort.sticky').each -> new SublimeVideo.UI.SortLink(jQuery(this))
