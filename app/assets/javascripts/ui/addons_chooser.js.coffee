# TODO
#
class MySublimeVideo.UI.AddonsChooser
  constructor: (@form) ->
    @addonsTotalDiv = $("#addons_total")
    @allInputs = @form.find('input[type=radio], input[type=checkbox]')

    # this.setupProcessDetailsMessages()
    this.setupInputsObservers()

  # setupProcessDetailsMessages: =>
  #   _.each ['in_trial_downgrade_to_free', 'in_trial_upgrade', 'skipping_trial_free', 'skipping_trial_paid', 'upgrade', 'upgrade_from_free', 'delayed_upgrade', 'delayed_downgrade', 'delayed_change', 'delayed_downgrade_to_free'], (name) =>
  #     @processDetailsMessages[name] = $("#plan_#{name}_info")

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

  # handlePlanChange: ->
  #   if @badgedDiv.exists()
  #     if this.checkedPlanPriceIsZero() then @badgedDiv.hide() else @badgedDiv.show()
  #   planChangeAndIsNotFree = !(this.checkedPlanIsCurrentPlan() or this.checkedPlanPriceIsZero())
  #   this.handleBillingInfo(planChangeAndIsNotFree)

  # handleBillingInfo: (show) ->
  #   if show then @billingInfoDiv.show() else @billingInfoDiv.hide()
  #   this.handleProcessDetails()

  # handleSubmitButtonDisplay: (show) ->
  #   if show then $('#site_submit').show() else $('#site_submit').hide()

  # checkedPlanIsCurrentPlan: ->
  #   @formType is 'update' and !@checkedPlan.attr('data-plan_change_type')?
  # checkedPlanIsAnUpgrade: ->
  #   !this.checkedPlanPriceIsZero() and (!@checkedPlan.attr('data-plan_change_type')? or /upgrade/.test(@checkedPlan.attr('data-plan_change_type')))
  # checkedPlanPriceIsZero: ->
  #   (@checkedPlan.attr('data-plan_update_price')? and @checkedPlan.attr('data-plan_update_price') is "$0") or @checkedPlan.attr('data-plan_price') is "$0"

  # trialSkippable: -> @skipTrialDiv.exists()

  # skippingTrial: -> this.trialSkippable() and @skipTrialCheckbox.attr('checked')?

  # priceWithVATText: (field) ->
  #   if @checkedPlan.attr('data-vat')?
  #     "<strong>#{@checkedPlan.attr("data-#{field}_vat")}</strong> (including #{@checkedPlan.attr("data-vat")} VAT)"
  #   else
  #     "<strong>#{@checkedPlan.attr("data-#{field}")}</strong>"

  # # Site is updatable it's not an upgrade, or it's an upgrade and billing infos present
  # siteIsUpdatable: ->
  #   !this.checkedPlanIsCurrentPlan() and (!this.checkedPlanIsAnUpgrade() or @billingInfoState is 'present')

  # handleProcessDetails: ->
  #   _.each @processDetailsMessages, (messageDiv) -> messageDiv.hide()

  #   if this.siteIsUpdatable()
  #     planChangeType = if this.skippingTrial()
  #       if this.checkedPlanPriceIsZero()
  #         'skipping_trial_free'
  #       else
  #         'skipping_trial_paid'
  #     else
  #       @checkedPlan.attr 'data-plan_change_type'

  #     _.each @processDetailsMessages, (messageDiv, type) =>
  #       this.updateProcessDetailsMessages(messageDiv) if planChangeType is type

  # updateProcessDetailsMessages: (messageDiv) ->
  #   _.each ['plan_title', 'plan_update_date', 'plan_cycle'], (className) =>
  #     messageDiv.find(".#{className}").html @checkedPlan.attr("data-#{className}")

  #   _.each ['plan_price', 'plan_update_price'], (className) =>
  #     text = if @checkedPlan.attr('data-vat')?
  #       "<strong>#{@checkedPlan.attr("data-#{className}_vat")}</strong> (including #{@checkedPlan.attr("data-vat")} VAT)"
  #     else
  #       @checkedPlan.attr("data-#{className}")
  #     messageDiv.find(".#{className}").html text
  #   messageDiv.show()
