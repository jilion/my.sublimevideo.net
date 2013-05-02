# Handles the displaying of:
#   - trial days remaining,
#   - submit button / "cc needed" text,
#   - total per month depending on selected add-ons.
#
class MySublimeVideo.UI.AddonsChooser
  constructor: (@form) ->
    @addonsTotalDiv = $('#addons_total')
    @allInputs      = @form.find('input[type=radio], input[type=checkbox]')
    @actionsDiv     = @form.find('.actions')

    this.setup()

  setup: ->
    @allInputs.each (index, el) =>
      $el = $(el)
      this.setupInputsObservers($el)
      this.toggleTrialNotice($el)
    this.updateTotal()
    this.updateSubmitButton()

  setupInputsObservers: ($el) ->
      $el.on 'click', =>
        this.toggleTrialNotice($el)
        this.updateTotal()
        this.updateSubmitButton()

  toggleTrialNotice: ($el) ->
    $("[name='#{$el.prop('name')}']").parents('tr').find('td .trial_days_remaining').hide()
    trialDaysRemainingDiv = $el.parents('tr').find('td .trial_days_remaining')
    setTimeout((-> if $el.prop('checked') then trialDaysRemainingDiv.show() else trialDaysRemainingDiv.hide()), 0)

  updateTotal: ->
    totalInCents = _.inject this.checkedInputs(), ((sum, el) ->
      sum + $(el).data('price')
    ), 0
    remainingCents = totalInCents % 100
    @addonsTotalDiv.html "$#{Math.floor(totalInCents / 100)}<sup>.#{remainingCents}</sup>"

  updateSubmitButton: ->
    unless @form.data('credit-card')
      if trialEnded = _.find(this.checkedInputs(), (el) -> $(el).data('trial-ended'))
        @actionsDiv.find('.submit').hide()
        @actionsDiv.find('.credit_card_needed').show()
      else
        @actionsDiv.find('.submit').show()
        @actionsDiv.find('.credit_card_needed').hide()

  checkedInputs: ->
    @form.find('input[type=radio]:checked, input[type=checkbox]:checked')