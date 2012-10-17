# TODO
#
class MySublimeVideo.UI.AddonsChooser
  constructor: (@form) ->
    @addonsTotalDiv = $("#addons_total")
    @allInputs = @form.find('input[type=radio], input[type=checkbox]')

    this.setupInputsObservers()

  setupInputsObservers: ->
    @allInputs.each (index, el) =>
      el = $(el)
      el.on 'click', =>
        this.toggleTrialNotice(el)
        this.updateTotal()

  toggleTrialNotice: (element) ->
    $("[name='#{element.attr('name')}']").parents('tr').find('td .trial_days_remaining').hide()
    trialDaysRemainingDiv = element.parents('tr').find('td .trial_days_remaining')
    if element.attr('checked')?
      trialDaysRemainingDiv.show()
    else
      trialDaysRemainingDiv.hide()

  updateTotal: ->
    totalInCents = _.inject @form.find('input[type=radio]:checked, input[type=checkbox]:checked'), ((sum, el) ->
      sum + $(el).data('price')
    ), 0
    remainingCents = totalInCents % 100
    @addonsTotalDiv.html "$#{Math.floor(totalInCents / 100)}<sup>.#{remainingCents}</sup>"
