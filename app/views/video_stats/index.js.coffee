<% if params[:since] %>

$('#last_60_minutes_plays_and_loads').html("<%= j(render 'last_60_minutes_plays_and_loads', stats_presenter: @stats_presenter) %>")

lisToRemove = []
<% @stats_presenter.last_plays.reverse.each_with_index do |play, i| %>
lisToRemove.push $('#last_plays ul li').eq(-(<%= i %>+1))
$('#last_plays ul li').eq(-(<%= i %>+1)).slideUp ->
  lisToRemove[<%= i %>].remove()
<% end %>

<% @stats_presenter.last_plays.reverse.each do |play| %>
li = $("<%= j(render partial: 'last_play', object: play) %>")
li.css(display: 'none')
$('#last_plays ul').prepend(li)
li.slideDown()

<% end %>

one_hour_ago = new Date() - 3600 * 1000

$('#last_plays ul li').each (index, el) ->
  $el = $(el)
  time = $el.data('time') * 1000
  $el.remove() if time < one_hour_ago

<% else %>

$('#last_stats_by_hour').html("<%= j(render 'last_stats_by_hour', site: @site, video_tag: @video_tag, stats_presenter: @stats_presenter) %>")

<% end %>

MySublimeVideo.videoStatsReady()
