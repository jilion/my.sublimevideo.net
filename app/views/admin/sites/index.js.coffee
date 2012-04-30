jQuery('#sites_table_wrap').html "<%= j(render 'sites') %>"
<% if params[:search] || params[:with_min_billable_video_views] %>
jQuery('#sites_title').html "<%= admin_sites_page_title(@sites) %>"
<% end %>
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareSortAndStickyLinks()