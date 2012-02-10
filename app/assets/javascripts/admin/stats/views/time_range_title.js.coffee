class AdminSublimeVideo.Views.TimeRangeTitleView extends Backbone.View
  template: JST['admin/stats/templates/_time_range_title']

  events:
    'click': 'toggleDatePicker'

  initialize: ->
    @options.period.bind 'change', this.render
    this.render()

  render: =>
    $('#time_range_title').removeClass('editable')
    $(@el).html(this.template(period: @options.period))
    if @options.period.get('type')?
      $(@el).find('.content').show()
      # $(@el).data().spinner.stop()
    else
      $(@el).find('.content').hide()
      $(@el).spin(spinOptions)
      $('#time_range_title').addClass('editable')

    this

  toggleDatePicker: (event) ->
    event.stopPropagation()
    AdminSublimeVideo.datePickersView.render()
