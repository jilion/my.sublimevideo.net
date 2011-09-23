class MSVStats.Models.Period extends Backbone.Model
  defaults:
    type:  null  # minutes / hours / days
    # Custom Period (days)
    startTime: null
    endTime:   null

  typeInterval: ->
    switch this.get('type')
      when 'minutes' then 60 * 1000
      when 'hours'   then 60 * 60 * 1000
      when 'days'    then 24 * 60 * 60 * 1000

  stats: ->
    switch this.get('type')
      when 'minutes' then MSVStats.statsMinutes
      when 'hours'   then MSVStats.statsHours
      when 'days'    then MSVStats.statsDays

  datesRange: ->
    [this.get('startTime'), this.get('endTime')]

  # periodTickInterval: ->
  #   count = this.get('count')
  #   if count < 10
  #     this.periodInterval()
  #   else if count < 25
  #     2 * this.periodInterval()
  #   else
  #     7 * this.periodInterval()

  # periodIsAvailabe: (value) ->
  #   minValueInt = MSVStats.Models.Period.periodValueToInt(this.get('minValue'))
  #   valueInt    = MSVStats.Models.Period.periodValueToInt(value)
  #   valueInt >= minValueInt

  setPeriod: (attributes, options = {}) ->
    attributes.startTime ||= null
    attributes.endTime   ||= null
    this.set(attributes, options)

  setCustomPeriod: (startTime, endTime, options = {}) ->
    this.set(startTime: _.min([startTime, endTime]), endTime: _.max([startTime, endTime]), type: 'days', options)

  autosetPeriod: (options = {}) ->
    if !MSVStats.statsMinutes.isEmpty() && !MSVStats.statsHours.isEmpty() && !MSVStats.statsDays.isEmpty()
      if MSVStats.statsMinutes.vvTotal() > 0
        this.setPeriod(type: 'minutes', options)
      else if MSVStats.statsHours.vvTotal() > 0
        this.setPeriod(type: 'hours', options)
      else if MSVStats.statsDays.length <= 30 || MSVStats.statsDays.vvTotal([MSVStats.statsDays.at(MSVStats.statsDays.length - 30).time(), MSVStats.statsDays.last().time()]) > 0
        this.setPeriod
          type:      'days'
          startTime: MSVStats.statsDays.at(MSVStats.statsDays.length - 30).time()
          endTime:   MSVStats.statsDays.last().time()
          options
      else
        this.setPeriod
          type:      'days'
          startTime: MSVStats.statsDays.first().time()
          endTime:   MSVStats.statsDays.last().time()
          options

  isSelected: (type) ->
    this.get('type') == type

  isCustom: ->
    this.get('startTime') != null && this.get('endTime') != null

  isClear: ->
    _.all @attributes, (attr) -> attr == null

  # @periodValueToInt: (value) ->
  #   [count, type] = value.split(' ')
  #   int = switch type
  #     when 'minutes'
  #       1000
  #     when 'hours'
  #       2000
  #     when 'days'
  #       3000
  #   int += (if count == 'all' then 1000 else parseInt(count))

  # @today: (options = {}) ->
  #   today = new Date()
  #   _date(Date.UTC(
  #     options.y ? today.getUTCFullYear()
  #     options.M ? today.getUTCMonth()
  #     options.d ? today.getUTCDate()
  #     options.h ? today.getUTCHours()
  #     options.m ? (if options.h? then 0 else today.getUTCMinutes())
  #     options.s ? (if options.h? || options.m? then 0 else today.getUTCSeconds())
  #   ))


