$('#sites_table_wrap').html "<%= j(render 'sites') %>"

SublimeVideo.UI.prepareRemoteLinks()
MySublimeVideo.UI.prepareSiteActionsSelector()
MySublimeVideo.UI.prepareEmbedCodePopups()
MySublimeVideo.UI.prepareSitesStatus()
