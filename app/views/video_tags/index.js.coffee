$('#video_tags_table_wrap').html "<%= j(render 'video_tags') %>"

sublimevideo.prepare()
SublimeVideo.UI.prepareRemoteLinks()

<%- sort_param = (params.keys & VideoTagsController::SORT_PARAMS).first %>
<%- value = params[sort_param] %>
MySublimeVideo.UI.videoTagsTable.updateSortParams("<%= sort_param %>", "<%= value %>")
