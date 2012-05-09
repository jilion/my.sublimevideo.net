<% if params[:mail_logs] %>
jQuery('#mail_logs_table_wrap').html "<%= j(render 'mail_logs') %>"
<% elsif params[:mail_templates] %>
jQuery('#mail_templates_table_wrap').html "<%= j(render 'mail_templates') %>"
<% end %>
jQuery('#table_spinner').hide()
jQuery(document.body).animate({ scrollTop: 0 })

SublimeVideo.UI.prepareRemoteLinks()