class MSVStats.Models.Period extends Backbone.Model
  defaults:
    last: 30     # number or 'all'
    type: 'days'  # minute / hour / day

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
      when 'days'
        'column'
      else
        'spline'

  periodTickInterval: ->
    last = this.get('last')
    if last < 10
      this.periodInterval()
    else if last < 25
      2 * this.periodInterval()
    else
      5 * this.periodInterval()

  setPeriod: (value) ->
    [last, type] = value.split(' ')
    this.set(last: last, type: type)

  @today: (options = {}) ->
    today = new Date()
    _date(Date.UTC(
      options.y ? today.getUTCFullYear()
      options.M ? today.getUTCMonth()
      options.d ? today.getUTCDate()
      options.h ? today.getUTCHours()
      options.m ? (if options.h? then 0 else today.getMinutes())
    ))
