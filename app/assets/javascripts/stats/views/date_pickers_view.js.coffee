class MSVStats.Views.DatePickersView extends Backbone.View
  initialize: ->
    $(document).bind 'click', this.close
    Mousetrap.bind 'esc', => this.close()

  events: ->
    'click':               'stopPropagation'
    'click button.cancel': 'close'
    'click button.apply':  'apply'

  render: ->
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

  apply: ->
    startTime = this.convertDateToUTC('#start_time_picker')
    endTime   = this.convertDateToUTC('#end_time_picker')
    MSVStats.period.setCustomPeriod(startTime, endTime)
    this.close()

  stopPropagation: (event) ->
    event.stopPropagation()

  showDatePickers: ->
    datePickersView = this
    startTime       = null
    endTime         = null
    dates = $('#start_time_picker, #end_time_picker').datepicker
      changeMonth: true
      changeYear:  true
      dateFormat:  'yy-m-d'
      minDate:     MSVStats.statsDays.first().date()
      maxDate:     MSVStats.statsDays.last().date()
      onSelect: (selectedDate) ->
        if @id is "start_time_picker"
          option    = "minDate"
          startTime = datePickersView.convertPickerDate(selectedDate)
        else
          option  = "maxDate"
          endTime = datePickersView.convertPickerDate(selectedDate)
        dates.not(this).datepicker('option', option, selectedDate)
    if MSVStats.period.isDays()
      $('#start_time_picker').datepicker('setDate', new Date(MSVStats.period.startTime()))
      $('#end_time_picker').datepicker('setDate', new Date(MSVStats.period.endTime()))
    else
      $('#start_time_picker').datepicker('setDate', new Date(MSVStats.statsDays.last().time() - 7 * 24 * 3600 * 1000) )
      $('#end_time_picker').datepicker('setDate', MSVStats.statsDays.last().date())

  destroyDatePickers: ->
    $('#start_time_picker, #end_time_picker').datepicker('destroy')

  convertPickerDate: (pickerDate) ->
    [year, month, day] = pickerDate.split('-')
    Date.UTC(year, parseInt(month, 10) - 1, day)

  convertDateToUTC: (datePicker) ->
    date = $(datePicker).datepicker('getDate')
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
