class MSVStats.Views.MinutesPeriodSelectorView extends Backbone.View

  events:
    'click': 'onClick'

  initialize: () ->
    _.bindAll(this, 'render')
    this.options.period.bind('change', this.render);
    this.options.statsMinutes.bind('reset', this.render);

  render: ->
    $('#minutes_period_vv_total').html(MSVStats.statsMinutes.vvTotal())
    return this

  onClick: ->
    alert 'onClick'
    this.options.period.setPeriod(type: 'minutes')
    # selectedPeriodValue = this.$('select').val()
    # if MSVStats.period.value() != selectedPeriodValue
    #   switch selectedPeriodValue
    #     # when 'custom' then this.showDatePickers()
    #     else
    #       # this.hideDatePickers()

  # hideDatePickers: ->
  #   $('#custom_dates_pickers').hide()
  #   $('#start_time_picker, #end_time_picker').datepicker('destroy')
  #
  # showDatePickers: ->
  #   $('#custom_dates_pickers').show()
  #   periodsSelectView = this
  #   startTime         = null
  #   endTime           = null
  #   dates = $('#start_time_picker, #end_time_picker').datepicker
  #     changeMonth: true
  #     changeYear:  true
  #     dateFormat:  'yy-m-d'
  #     minDate:     MSVStats.stats.firstStatsDate()
  #     maxDate:     MSVStats.Models.Period.today(h: 0).date
  #     onSelect: (selectedDate) ->
  #       if (this.id == "start_time_picker")
  #         option    = "minDate"
  #         startTime = periodsSelectView.convertPickerDate(selectedDate)
  #       else
  #         option    = "maxDate"
  #         endTime   = periodsSelectView.convertPickerDate(selectedDate)
  #       dates.not(this).datepicker('option', option, selectedDate)
  #       if startTime != null && endTime != null
  #         periodsSelectView.hideDatePickers()
  #         MSVStats.period.setCustomPeriod(startTime, endTime)
  #
  # convertPickerDate: (pickerDate) ->
  #   [year, month, day] = pickerDate.split('-')
  #   Date.UTC(year, parseInt(month) - 1, day)
