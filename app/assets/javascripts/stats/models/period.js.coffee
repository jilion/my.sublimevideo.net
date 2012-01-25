class MSVStats.Models.Period extends Backbone.Model
  defaults:
    type: null  # minutes / hours / days
    # Custom Period (days)
    startIndex: 0
    endIndex: -1
    # For Seconds stats
    startSecondsTime: null
    endSecondsTime: null

  pointInterval: ->
    switch this.get('type')
      when 'seconds' then 1000
      when 'minutes' then 60 * 1000
      when 'hours'   then 60 * 60 * 1000
      when 'days'    then 24 * 60 * 60 * 1000

  stats: ->
    switch this.get('type')
      when 'seconds' then MSVStats.statsSeconds
      when 'minutes' then MSVStats.statsMinutes
      when 'hours'   then MSVStats.statsHours
      when 'days'    then MSVStats.statsDays

  timeRange: ->
    [this.startTime(), this.endTime()]

  isFullRange: ->
    this.get('startIndex') == 0 && this.get('endIndex') == -1

  isSelected: (type, startIndex, endIndex) ->
    this.get('type') == type &&
    this.normalizeStatsIndex(this.get('startIndex')) == this.normalizeStatsIndex(startIndex) &&
    this.normalizeStatsIndex(this.get('endIndex')) == this.normalizeStatsIndex(endIndex)

  isSeconds: -> this.get('type') == 'seconds'
  isMinutes: -> this.get('type') == 'minutes'
  isHours:   -> this.get('type') == 'hours'
  isDays:    -> this.get('type') == 'days'

  startTime: (index = this.get('startIndex')) ->
    if this.stats()?
      if this.isSeconds()
        this.get('startSecondsTime')
      else
        this.stats().at(this.normalizeStatsIndex(index)).time()
    else
      0

  endTime: (index = this.get('endIndex')) ->
    if this.stats()?
      if this.isSeconds()
        this.get('endSecondsTime')
      else
        this.stats().at(this.normalizeStatsIndex(index)).time()
    else
      0

  startIndex: ->
    this.normalizeStatsIndex(this.get('startIndex'))

  endIndex: ->
    this.normalizeStatsIndex(this.get('endIndex'))

  realEndTime: (index = this.get('endIndex')) ->
    this.endTime(index) + this.pointInterval() - 1000 if this.stats()?

  normalizeStatsIndex: (index) ->
    if index < 0 then this.stats().length + index else index

  setPeriod: (attributes, options = {}) ->
    attributes.startIndex ||= 0
    attributes.endIndex   ||= -1
    this.set(attributes, options)

  setCustomPeriod: (startTime, endTime, options = {}) ->
    startIndex = MSVStats.statsDays.indexOf(MSVStats.statsDays.get(startTime / 1000))
    endIndex   = MSVStats.statsDays.indexOf(MSVStats.statsDays.get(endTime / 1000))
    this.set(type: 'days', startIndex: startIndex, endIndex: endIndex, options)

  autosetPeriod: ->
    MSVStats.statsDays.trigger('init') # for planUsageView
    
    if MSVStats.statsMinutes.vvTotal() > 0
      this.setPeriod type: 'minutes'
    else if MSVStats.statsHours.vvTotal() > 0 || MSVStats.sites.selectedSiteIsInFreePlan()
      this.setPeriod type: 'hours'
    else if MSVStats.statsDays.length <= 30 || MSVStats.statsDays.vvTotal(-30, -1) > 0
      this.setPeriod type: 'days', startIndex: -30, endIndex: -1
    else # last 365 days
      this.setPeriod type: 'days', startIndex: -365, endIndex: -1
