#= require eventsource

class MySublimeVideo.Helpers.StatsPoller
  constructor: (@div) ->
    console.log 'yeah'

    eventSource = new EventSource('http://0.0.0.0:3000/plays?site_token=s&video_uid=u')
    eventSource.addEventListener "message", (event) -> console.log "message: #{event.data}"
    eventSource.addEventListener "heartbeat", (event) -> console.log "heartbeat"
