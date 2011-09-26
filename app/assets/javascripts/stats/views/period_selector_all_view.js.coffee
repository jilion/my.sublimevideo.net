class MSVStats.Views.PeriodSelectorAllView extends Backbone.View

  initialize: () ->
    @el = $('#period_selectors .all')
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @el.bind('click', _.bind(this.select, this))

  render: ->
    if this.isSelected() then @el.addClass('selected') else @el.removeClass('selected')
    return this

  select: ->
    @options.period.setPeriod type: 'days', startIndex: 0, endIndex: -1

  isSelected: ->
    @options.period.get('type') == 'days' && @options.period.get('startIndex') == 0 && @options.period.get('endIndex') == -1

