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
    startTime = this.convertDateToUTC('#start_time_picker')
    endTime   = this.convertDateToUTC('#end_time_picker')
    # AdminSublimeVideo.period.setCustomPeriod(startTime, endTime)
    AdminSublimeVideo.statsRouter.xAxisMin = startTime
    AdminSublimeVideo.statsRouter.xAxisMax = endTime
    this.close()

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
      minDate:     new Date(AdminSublimeVideo.statsRouter.xAxisMin)
      maxDate:     new Date(AdminSublimeVideo.statsRouter.xAxisMax)
      onSelect: (selectedDate) ->
        if (this.id == "start_time_picker")
          option    = "minDate"
          startTime = datePickersView.convertPickerDate(selectedDate)
        else
          option    = "maxDate"
          endTime   = datePickersView.convertPickerDate(selectedDate)
        dates.not(this).datepicker('option', option, selectedDate)
    # $('#start_time_picker').datepicker('setDate', new Date(AdminSublimeVideo.period.startTime()))
    # $('#end_time_picker').datepicker('setDate', new Date(AdminSublimeVideo.period.endTime()))
    $('#start_time_picker').datepicker('setDate', new Date(AdminSublimeVideo.statsRouter.xAxisMin))
    $('#end_time_picker').datepicker('setDate', new Date(AdminSublimeVideo.statsRouter.xAxisMax))

  destroyDatePickers: ->
    $('#start_time_picker, #end_time_picker').datepicker('destroy')

  convertPickerDate: (pickerDate) ->
    [year, month, day] = pickerDate.split('-')
    Date.UTC(year, parseInt(month) - 1, day)

  convertDateToUTC: (datePicker) ->
    date = $(datePicker).datepicker('getDate')
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
