<% if params[:since] %>

$('#last_60_minutes_plays_and_loads').html("<%= j(render 'stats/last_60_minutes_plays_and_loads', stats_presenter: @stats_presenter) %>")

# Add new plays
<% @stats_presenter.last_plays.reverse.each do |play| %>
li = $("<%= j(render partial: 'last_play', object: play) %>")
li.css(display: 'none')
$('#last_plays ul').prepend(li)
li.slideDown()
<% end %>

# Remove plays older than an hour
one_hour_ago = new Date() - 3600 * 1000
$('#last_plays ul li').each (index, el) ->
  $el = $(el)
  time = $el.data('time') * 1000
  $el.remove() if time < one_hour_ago

# Remove plays until there's no more than 100 plays
$('#last_plays ul li').last().remove() while $('#last_plays ul li').length > 100

MySublimeVideo.statsReady.topStatsReady()
<% else %>

$('#last_stats_by_hour_or_day').html("<%= j(render 'stats/last_stats_by_hour_or_day', site: @site, video_tag: @video_tag, stats_presenter: @stats_presenter) %>")

MySublimeVideo.statsReady.bottomStatsReady()
<% end %>

