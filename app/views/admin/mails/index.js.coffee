<% if params[:mail_logs] %>
$('#mail_logs_table_wrap').html "<%= j(render 'mail_logs') %>"
<% elsif params[:mail_templates] %>
$('#mail_templates_table_wrap').html "<%= j(render 'mail_templates') %>"
<% end %>
$('#table_spinner').hide()
$(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()
