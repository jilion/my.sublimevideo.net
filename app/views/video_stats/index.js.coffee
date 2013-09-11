$('#timerange_stats').html "<%= j(render 'timerange_stats', site: @site, video: @video, stats: @stats) %>"
MySublimeVideo.videoStatsReady()
