class MSVStats.Models.Period extends Backbone.Model
  defaults:
    last:      '30'    # number or 'all'
    type:      'days'  # minutes / hours / days
    minValue:  '60 minutes'
    # Custom Period
    startTime: null
    endTime:   null


  value: ->
    "#{this.get('last')} #{this.get('type')}"

  periodInterval: ->
    switch this.get('type')
      when 'minutes'
        60 * 1000
      when 'hours'
        60 * 60 * 1000
      when 'days'
        24 * 60 * 60 * 1000

  periodChartTitle: (x) ->
    switch this.get('type')
      when 'minutes'
        "#{Highcharts.dateFormat('%e %B %Y, %H:%M', x - MSVStats.period.periodInterval())} - #{Highcharts.dateFormat('%e %B %Y, %H:%M', x)}"
      else
        "#{Highcharts.dateFormat('%e %B %Y, %H:%M', x)} - #{Highcharts.dateFormat('%e %B %Y, %H:%M', x + MSVStats.period.periodInterval())}"

  periodChartType: ->
    switch this.get('type')
      when 'days' then 'spline'
      else 'spline'

  # periodTickInterval: ->
  #   last = this.get('last')
  #   if last < 10
  #     this.periodInterval()
  #   else if last < 25
  #     2 * this.periodInterval()
  #   else
  #     7 * this.periodInterval()

  periodIsAvailabe: (value) ->
    minValueInt = MSVStats.Models.Period.periodValueToInt(this.get('minValue'))
    valueInt    = MSVStats.Models.Period.periodValueToInt(value)
    valueInt >= minValueInt

  setPeriod: (value, options = {}) ->
    [last, type] = value.split(' ')
    attributes = last: last, type: type, startTime: null, endTime: null
    _.extend(attributes, minValue: value) if options.isMinValue
    this.set(attributes, options)

  setCustomPeriod: (startTime, endTime, options = {}) ->
    this.set(startTime: Math.min(startTime, endTime), endTime: Math.max(startTime, endTime), last: null, type: 'days', options)

  autosetPeriod: (options = {}) ->
    _.extend(options, isMinValue: true)
    if MSVStats.stats.forCurrentPeriodType('minutes').length > 0
      this.setPeriod('60 minutes', options)
    else if MSVStats.stats.forCurrentPeriodType('hours').length > 0
      this.setPeriod('24 hours', options)
    else if MSVStats.stats.forCurrentPeriodType('days', MSVStats.Models.Period.today(h: 0).subtract(d: 6).date.getTime()).length > 0
      this.setPeriod('7 days', options)
    else if MSVStats.stats.forCurrentPeriodType('days', MSVStats.Models.Period.today(h: 0).subtract(d: 29).date.getTime()).length > 0
      this.setPeriod('30 days', options)
    else
      this.setPeriod('all days', options)

  isCustom: ->
    this.get('startTime') != null && this.get('endTime') != null

  @periodValueToInt: (value) ->
    [last, type] = value.split(' ')
    int = switch type
      when 'minutes'
        1000
      when 'hours'
        2000
      when 'days'
        3000
    int += (if last == 'all' then 1000 else parseInt(last))

  @today: (options = {}) ->
    today = new Date()
    _date(Date.UTC(
      options.y ? today.getUTCFullYear()
      options.M ? today.getUTCMonth()
      options.d ? today.getUTCDate()
      options.h ? today.getUTCHours()
      options.m ? (if options.h? then 0 else today.getUTCMinutes())
      options.s ? (if options.h? || options.m? then 0 else today.getUTCSeconds())
    ))


