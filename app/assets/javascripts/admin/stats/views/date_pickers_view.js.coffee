class AdminSublimeVideo.Views.DatePickersView extends Backbone.View
  template: JST['templates/_date_pickers']

  events:
    'click':               'stopPropagation'
    'click button.cancel': 'close'
    'click button.apply':  'apply'

  initialize: ->
    $(@el).html(this.template())
    $(document).click this.close
    $(document).keydown this.closeIfEsc

  render: ->
    if $(@el).is(":visible") then this.close() else this.show()

    this

  show: ->
    $(@el).show()
    this.showDatePickers()

  close: =>
    $(@el).hide()
    this.destroyDatePickers()

  closeIfEsc: (event) =>
    if event.keyCode == 27
      $(@el).hide()
      this.destroyDatePickers()

  apply: ->
    newStart = this.convertDateToUTC('#start_time_picker')
    newEnd   = this.convertDateToUTC('#end_time_picker')
    AdminSublimeVideo.period.start = new Date newStart
    AdminSublimeVideo.period.end   = new Date newEnd
    AdminSublimeVideo.statsRouter.updateUrl('p', "#{newStart}-#{newEnd}")
    this.close()
    AdminSublimeVideo.period.trigger('change')

  stopPropagation: (event) ->
    event.stopPropagation()

  showDatePickers: ->
    datePickersView = this
    startTime         = null
    endTime           = null
    dates = $('#start_time_picker, #end_time_picker').datepicker
      changeMonth: true
      changeYear:  true
      dateFormat:  'yy-m-d'
      minDate:     new Date Date.UTC(2010, 8, 14)
      maxDate:     new Date()
      onSelect: (selectedDate) ->
        if (this.id == "start_time_picker")
          option    = "minDate"
          startTime = datePickersView.convertPickerDate(selectedDate)
        else
          option    = "maxDate"
          endTime   = datePickersView.convertPickerDate(selectedDate)
        dates.not(this).datepicker('option', option, selectedDate)
    $('#start_time_picker').datepicker('setDate', AdminSublimeVideo.period.start)
    $('#end_time_picker').datepicker('setDate', AdminSublimeVideo.period.end)

  destroyDatePickers: ->
    $('#start_time_picker, #end_time_picker').datepicker('destroy')

  convertPickerDate: (pickerDate) ->
    [year, month, day] = pickerDate.split('-')
    Date.UTC(year, parseInt(month) - 1, day)

  convertDateToUTC: (datePicker) ->
    date = $(datePicker).datepicker('getDate')
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
