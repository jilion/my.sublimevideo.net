class AdminSublimeVideo.Views.PeriodSelector extends Backbone.View
  events:
    'click a': 'applyPreset'

  applyPreset: (event) ->
    event.stopPropagation()
    preset = $(event.target).parent('li').attr('class').split('-')

    newStart = AdminSublimeVideo.statsChart.series[0].xAxis.getExtremes()['min']
    _.each AdminSublimeVideo.statsChart.series, (serie) ->
      newStart = serie.xAxis.getExtremes()['min'] if serie.xAxis.getExtremes()['min'] < newStart
    newEnd = new Date()

    if preset[0] is 'all'
      AdminSublimeVideo.period.start = new Date(newStart)
      AdminSublimeVideo.period.end   = newEnd
    else
      newStartScale = switch preset[0]
        when 'years' then this.year()
        when 'months' then this.month()
        when 'days' then this.day()
      newStart = _.max([newStart, AdminSublimeVideo.period.endTime() - (newStartScale * preset[1])])
      AdminSublimeVideo.period.start = new Date newStart

    AdminSublimeVideo.statsRouter.updateUrl('p', "#{newStart}-#{newEnd.getTime()}")
    AdminSublimeVideo.graphView.render()

    false

  day: -> 1000 * 3600 * 24
  month: -> this.day() * 30
  year: -> this.day() * 365
