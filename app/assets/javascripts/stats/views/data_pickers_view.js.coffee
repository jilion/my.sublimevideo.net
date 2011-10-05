class MSVStats.Views.DatePickersView extends Backbone.View
  template: JST['stats/templates/_date_pickers']

  events:
    'click':               'stopPropagation'
    'click button.cancel': 'close'
    'click button.apply':  'apply'

  initialize: ->
    $(document).click ->
      MSVStats.datePickersView.close()
    $(@el).html(this.template())

  render: ->
    if $(@el).is(":visible") then this.close() else this.show()
    return this
    
  show: ->
    $(@el).show()
    this.showDatePickers()
    
  close: ->
    $(@el).hide()
    $('#start_time_picker, #end_time_picker').datepicker('destroy')
    
  apply: ->
    console.log 'apply'
    this.close()

  stopPropagation: (event) ->
    event.stopPropagation()

  # updatePeriod: ->
  #   selectedPeriodValue = this.$('select').val()
  #   if MSVStats.period.value() != selectedPeriodValue
  #     switch selectedPeriodValue
  #       when 'custom' then this.showDatePickers()
  #       else
  #         this.hideDatePickers()
  #         this.options.period.setPeriod(selectedPeriodValue)

  showDatePickers: ->
    datePickersView = this
    startTime         = null
    endTime           = null
    dates = $('#start_time_picker, #end_time_picker').datepicker
      changeMonth: true
      changeYear:  true
      dateFormat:  'yy-m-d'
      minDate:     MSVStats.statsDays.first().date()
      maxDate:     MSVStats.statsDays.last().date()
      onSelect: (selectedDate) ->
        if (this.id == "start_time_picker")
          option    = "minDate"
          startTime = datePickersView.convertPickerDate(selectedDate)
        else
          option    = "maxDate"
          endTime   = datePickersView.convertPickerDate(selectedDate)
        dates.not(this).datepicker('option', option, selectedDate)
  
  convertPickerDate: (pickerDate) ->
    [year, month, day] = pickerDate.split('-')
    Date.UTC(year, parseInt(month) - 1, day)