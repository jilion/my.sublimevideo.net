jQuery('#sites_table_wrap').html "<%= j(render 'sites') %>"
jQuery('a.sort.sticky').each ->
  new SublimeVideo.UI.SortLink(jQuery(this))
