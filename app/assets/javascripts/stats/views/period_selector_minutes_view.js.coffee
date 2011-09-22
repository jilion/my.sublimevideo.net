class MSVStats.Views.PeriodSelectorMinutesView extends Backbone.View

  # events:
  #   'click': 'onClick'

  initialize: () ->
    @el = $('#period_selectors .minutes')
    _.bindAll(this, 'render')
    @options.period.bind('change', this.render)
    @options.statsMinutes.bind('reset', this.render)
    @el.bind 'click', ->
      MSVStats.period.setPeriod(type: 'minutes')

  render: ->
    if this.isSelected() then @el.addClass('selected') else @el.removeClass('selected')
    $('#period_minutes_vv_total').html(@options.statsMinutes.vvTotal())
    this.renderSparkline()
    return this
    
  renderSparkline: ->
    $('#period_minutes_sparkline').sparkline @options.statsMinutes.pluck('vv'),
      width: '100%'
      height: '50px'
      lineColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      fillColor: if this.isSelected() then '#0046ff' else '#00b1ff'
      
  isSelected: ->
    @options.period.isSelected('minutes')

  # onClick: ->
  #   alert 'onClick'
  #   this.options.period.setPeriod(type: 'minutes')
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
