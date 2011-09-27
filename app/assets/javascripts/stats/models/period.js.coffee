class MSVStats.Models.Period extends Backbone.Model
  defaults:
    type:  null  # minutes / hours / days
    # Custom Period (days)
    startIndex: 0
    endIndex: -1

  typeInterval: ->
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

  datesRange: ->
    [this.startTime(), this.endTime()]

  isFullRange: ->
    this.get('startIndex') == 0 && this.get('endIndex') == -1

  startTime: (index = this.get('startIndex')) ->
    this.stats().at(this.normalizeStatsIndex(index)).time() if this.stats()?

  endTime: (index = this.get('endIndex')) ->
    this.stats().at(this.normalizeStatsIndex(index)).time() if this.stats()?

  normalizeStatsIndex: (index) ->
    if index < 0 then this.stats().length + index else index

  setPeriod: (attributes, options = {}) ->
    attributes.startIndex ||= 0
    attributes.endIndex   ||= -1
    this.set(attributes, options)

  # setCustomPeriod: (startTime, endTime, options = {}) ->
  #   this.set(startTime: _.min([startTime, endTime]), endTime: _.max([startTime, endTime]), type: 'days', options)

  autosetPeriod: (options = {}) ->
    if MSVStats.statsSeconds.vvTotal() > 0
      this.setPeriod type: 'seconds', options
    else if MSVStats.statsMinutes.vvTotal() > 0
      this.setPeriod type: 'minutes', options
    else if MSVStats.statsHours.vvTotal() > 0
      this.setPeriod type: 'hours', options
    else if MSVStats.statsDays.length <= 30 || MSVStats.statsDays.vvTotal([MSVStats.statsDays.at(MSVStats.statsDays.length - 30).time(), MSVStats.statsDays.last().time()]) > 0
      this.setPeriod type: 'days', startIndex: -30, endIndex: -1, options
    else # all
      this.setPeriod type: 'days', options


