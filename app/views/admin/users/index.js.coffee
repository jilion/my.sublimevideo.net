document.title = document.title.replace /- .+/, "- <%= admin_users_page_title(@users) %>"
jQuery('#content h2').html "<%= admin_users_page_title(@users) %>"
jQuery('#users_table_wrap').html "<%= j(render 'users') %>"
jQuery('#table_spinner').hide()

SublimeVideo.UI.prepareRemoteLinks()