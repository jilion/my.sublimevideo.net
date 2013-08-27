class AdminSublimeVideo.Views.DatePickersView extends Backbone.View
  template: JST['admin/trends/templates/date_pickers']

  initialize: ->
    $(document).bind 'click', this.close
    Mousetrap.bind 'esc', => this.close()
    this.render()

  events: ->
    'click':               '_stopPropagation'
    'click button.apply':  '_apply'
    'click button.cancel': 'close'

  render: ->
    @$el.html(this.template())
    this

  toggle: ->
    if @$el.is(":visible")
      this.close()
    else
      this.show()
    this

  show: ->
    @$el.show()
    this.showDatePickers()

  close: =>
    @$el.hide()
    this.destroyDatePickers()

  showDatePickers: ->
    datePickersView = this
    startTime       = null
    endTime         = null
    dates = $('#start_time_picker, #end_time_picker').datepicker
      changeMonth: true
      changeYear:  true
      dateFormat:  'yy-m-d'
      minDate:     new Date Date.UTC(2010, 8, 14)
      maxDate:     new Date()
      onSelect: (selectedDate) ->
        if @id is 'start_time_picker'
          option    = "minDate"
          startTime = datePickersView.convertPickerDate(selectedDate)
        else
          option  = "maxDate"
          endTime = datePickersView.convertPickerDate(selectedDate)
        dates.not(this).datepicker('option', option, selectedDate)
    $('#start_time_picker').datepicker 'setDate', AdminSublimeVideo.period.get('start')
    $('#end_time_picker').datepicker 'setDate', AdminSublimeVideo.period.get('end')

  destroyDatePickers: ->
    $('#start_time_picker, #end_time_picker').datepicker('destroy')

  convertPickerDate: (pickerDate) ->
    [year, month, day] = pickerDate.split('-')
    Date.UTC(year, parseInt(month) - 1, day)

  convertDateToUTC: (datePicker) ->
    date = $(datePicker).datepicker('getDate')
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())

  #
  # PRIVATE
  #
  _stopPropagation: (event) ->
    event.stopPropagation()

  _apply: ->
    newStart = this.convertDateToUTC('#start_time_picker')
    newEnd   = this.convertDateToUTC('#end_time_picker')
    AdminSublimeVideo.period.set(start: new Date(newStart), end: new Date(newEnd))
    AdminSublimeVideo.trendsRouter.updateUrl('p', "#{newStart}-#{newEnd}")
    this.close()
    AdminSublimeVideo.graphView.render()
