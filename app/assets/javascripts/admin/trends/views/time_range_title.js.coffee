class AdminSublimeVideo.Views.TimeRangeTitleView extends Backbone.View
  template: JST['admin/trends/templates/time_range_title']

  initialize: ->
    this._listenToModelsEvents()
    this.render()

  events: ->
    'click': '_toggleDatePicker'

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(AdminSublimeVideo.period, 'change', this.render)

  render: =>
    $('#time_range_title').removeClass('editable')
    @$el.html(this.template(period: AdminSublimeVideo.period))
    this.$('.content').show()

    this

  #
  # PRIVATE
  #
  _toggleDatePicker: (event) ->
    event.stopPropagation()
    AdminSublimeVideo.datePickersView.toggle()
