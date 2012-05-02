jQuery('#enthusiasts_table_wrap').html "<%= j(render 'enthusiasts') %>"
<% if params[:search] %>
jQuery('#enthusiasts_title').html "<%= admin_enthusiasts_page_title(@enthusiasts) %>"
<% end %>
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareSortAndStickyLinks()