class AdminSublimeVideo.Views.PeriodSelector extends Backbone.View
  events:
    'click a': 'applyPreset'

  applyPreset: (event) ->
    preset = $(event.target).parent('li').attr('class').split('-')

    minStart = AdminSublimeVideo.statsChart.series[0].xAxis.getExtremes()['min']
    _.each AdminSublimeVideo.statsChart.series, (serie) ->
      minStart = serie.xAxis.getExtremes()['min'] if serie.xAxis.getExtremes()['min'] < minStart

    if preset[0] is 'all'
      AdminSublimeVideo.period.start = new Date(minStart)
      AdminSublimeVideo.period.end   = new Date()
    else
      newStartScale = switch preset[0]
        when 'years' then this.year()
        when 'months' then this.month()
        when 'days' then this.day()
      AdminSublimeVideo.period.start = new Date _.max([minStart, AdminSublimeVideo.period.endTime() - (newStartScale * preset[1])])

    AdminSublimeVideo.period.trigger('change')

  day: -> 1000 * 3600 * 24
  month: -> this.day() * 30
  year: -> this.day() * 365
