class AdminSublimeVideo.Models.Period extends Backbone.Model
  defaults:
    type: null  # minutes / hours / days
    # Custom Period (days)
    startTime: new Date(new Date - 3600*24*1000*30)
    endTime: new Date

  pointInterval: ->
    switch this.get('type')
      when 'seconds' then 1000
      when 'minutes' then 60 * 1000
      when 'hours'   then 60 * 60 * 1000
      when 'days'    then 24 * 60 * 60 * 1000

  timeRange: ->
    [this.startTime(), this.endTime()]

  isFullRange: ->
    this.get('startIndex') == 0 && this.get('endIndex') == -1

  isSeconds: -> this.get('type') == 'seconds'
  isMinutes: -> this.get('type') == 'minutes'
  isHours:   -> this.get('type') == 'hours'
  isDays:    -> this.get('type') == 'days'

  startTime: ->
    this.get('startTime')

  endTime: ->
    this.get('endTime')

  realEndTime: ->
    this.get('endTime')

  setPeriod: (attributes, options = {}) ->
    attributes.startIndex ||= 0
    attributes.endIndex   ||= -1
    this.set(attributes, options)

  setCustomPeriod: (startTime, endTime, options = {}) ->
    startIndex = MSVStats.statsDays.indexOf(MSVStats.statsDays.get(startTime / 1000))
    endIndex   = MSVStats.statsDays.indexOf(MSVStats.statsDays.get(endTime / 1000))
    this.set(type: 'days', startIndex: startIndex, endIndex: endIndex, options)
