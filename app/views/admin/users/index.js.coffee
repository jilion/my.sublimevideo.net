jQuery('#users_table_wrap').html "<%= j(render 'users') %>"
<% if params[:search] %>
jQuery('#users_title').html "<%= admin_users_page_title(@users) %>"
<% end %>
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })
jQuery('a.sort.sticky').each -> new SublimeVideo.UI.SortLink(jQuery(this))
