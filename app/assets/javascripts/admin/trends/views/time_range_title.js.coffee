class AdminSublimeVideo.Views.TimeRangeTitleView extends Backbone.View
  template: JST['admin/trends/templates/time_range_title']

  events:
    'click': 'toggleDatePicker'

  initialize: ->
    @options.period.bind 'change', this.render
    this.render()

  render: =>
    $('#time_range_title').removeClass('editable')
    $(@el).html(this.template(period: @options.period))
    $(@el).find('.content').show()

    this

  toggleDatePicker: (event) ->
    event.stopPropagation()
    AdminSublimeVideo.datePickersView.render()
