$('#timerange_stats').html "<%= j(render 'timerange_stats', site: @site, video_tag: @video_tag, stats: @stats) %>"
MySublimeVideo.videoStatsReady()
