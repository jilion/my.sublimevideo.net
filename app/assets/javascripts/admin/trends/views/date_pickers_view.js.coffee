class AdminSublimeVideo.Views.DatePickersView extends Backbone.View
  initialize: ->
    $(document).bind 'click', this.close
    Mousetrap.bind 'esc', => this.close()

  events: ->
    'click':               '_stopPropagation'
    'click button.cancel': '_close'
    'click button.apply':  '_apply'

  render: ->
    if @$el.is(":visible")
      this.close()
    else
      this.show()

    this

  show: ->
    @$el.show()
    this.showDatePickers()

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
    $('#start_time_picker').datepicker 'setDate', @options.period.get('start')
    $('#end_time_picker').datepicker 'setDate', @options.period.get('end')

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

  _close: =>
    @$el.hide()
    this.destroyDatePickers()

  _apply: ->
    newStart = this.convertDateToUTC('#start_time_picker')
    newEnd   = this.convertDateToUTC('#end_time_picker')
    @options.period.set(start: new Date(newStart), end: new Date(newEnd))
    AdminSublimeVideo.trendsRouter.updateUrl('p', "#{newStart}-#{newEnd}")
    this.close()
    AdminSublimeVideo.graphView.render()
