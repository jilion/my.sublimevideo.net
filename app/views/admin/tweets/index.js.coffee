jQuery('#tweets_table_wrap').html "<%= j(render 'tweets') %>"
jQuery('#table_spinner').hide()
jQuery('#users_title').html "<%= pluralize(@tweets.count, 'Tweet') %>"
jQuery(document.body).scrollTo()
jQuery(document.body).animate({ scrollTop: 0 })
jQuery('a.sort.sticky').each -> new SublimeVideo.UI.SortLink(jQuery(this))

