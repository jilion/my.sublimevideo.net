class MSVStats.Models.Period extends Backbone.Model
  defaults:
    last: 30     # number or 'all'
    type: 'days'  # minute / hour / day

  value: ->
    "#{this.get('last')} #{this.get('type')}"

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
