document.title = document.title.replace /- .+/, "- <%= admin_users_page_title(@users) %>"
$('#content h2').html "<%= admin_users_page_title(@users) %>"
$('#users_table_wrap').html "<%= j(render 'users') %>"
$('#table_spinner').hide()

SublimeVideo.UI.prepareRemoteLinks()
