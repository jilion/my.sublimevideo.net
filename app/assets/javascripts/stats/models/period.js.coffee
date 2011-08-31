class MSVStats.Models.Period extends Backbone.Model
  defaults:
    last: 30     # number or 'all'
    type: 'days'  # minute / hour / day

  value: ->
    "#{this.get('last')} #{this.get('type')}"

  setPeriod: (value) ->
    [last, type] = value.split(' ')
    this.set(last: last, type: type)
