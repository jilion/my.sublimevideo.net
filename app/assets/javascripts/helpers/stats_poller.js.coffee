#= require eventsource

class MySublimeVideo.Helpers.StatsPoller
  constructor: (@div) ->
    authToken = @div.data('auth-token')
    eventSource = new EventSource("https://stats.sublimevideo.net/plays?auth=#{authToken}")
    eventSource.addEventListener "message", (event) -> console.log "message: #{event.data}"
    eventSource.addEventListener "heartbeat", (event) -> console.log "heartbeat"
