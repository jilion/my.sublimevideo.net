$('#enthusiasts_table_wrap').html "<%= j(render 'enthusiasts') %>"
<% if params[:search] %>
$('#enthusiasts_title').html "<%= admin_enthusiasts_page_title(@enthusiasts) %>"
<% end %>
$('#table_spinner').hide()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
