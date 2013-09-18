<% if params[:last_stats_by_minute_only] %>
$('#last_stats_by_minute').html("<%= j(render 'last_stats_by_minute', site: @site, video_tag: @video_tag, stats_presenter: @stats_presenter) %>")
<% else %>
$('#last_stats_by_hour').html("<%= j(render 'last_stats_by_hour', site: @site, video_tag: @video_tag, stats_presenter: @stats_presenter) %>")
<% end %>

MySublimeVideo.videoStatsReady()
