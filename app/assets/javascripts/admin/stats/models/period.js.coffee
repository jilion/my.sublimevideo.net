class AdminSublimeVideo.Models.Period extends Backbone.Model
  initialize: ->
    max = new Date()
    min = new Date(max - (1000 * 3600 * 24 * 30))
    @start = new Date(Date.UTC(min.getFullYear(), min.getMonth(), min.getDate()))
    @end   = new Date(Date.UTC(max.getFullYear(), max.getMonth(), max.getDate()))

  timeRange: ->
    [this.startTime(), this.endTime()]

  startTime: -> @start.getTime()

  endTime: -> @end.getTime()

  realEndTime: -> this.endTime()
