# Plan update manager for sites that are persisted (they can be in trial or not) [/sites/:token/plan/edit]
#
class MySublimeVideo.UI.PersistedSitePlanChooser extends MySublimeVideo.UI.PlanChooser
  constructor: ->
    @formType = 'update'
    @processDetailsMessages = {}
    super
    this.setupProcessDetailsMessages()

  setupProcessDetailsMessages: =>
    _.each ['in_trial_downgrade_to_free', 'in_trial_update', 'in_trial_instant_upgrade', 'skipping_trial', 'upgrade', 'upgrade_from_free', 'delayed_upgrade', 'delayed_downgrade', 'delayed_change', 'delayed_downgrade_to_free'], (name) =>
      @processDetailsMessages[name] = jQuery("#plan_#{name}_info")

  handleBillingInfo: (show) ->
    super
    this.handleSubmitButtonDisplay(!this.checkedPlanIsCurrentPlan() and (this.checkedPlanPriceIsZero() or this.siteIsUpdatable()))

  # Site is updatable if:
  #  - it's in trial and don't skip trial, or skip trial and billing infos present
  #  - it's not in trial and don't upgrade, or upgrade and billing infos present
  siteIsUpdatable: ->
    (this.siteIsInTrial() and (!this.skippingTrial() or @billingInfoState is 'present')) or (!this.siteIsInTrial() and !this.checkedPlanIsCurrentPlan() and (!this.checkedPlanIsAnUpgrade() or @billingInfoState is 'present'))

  handleProcessDetails: ->
    _.each @processDetailsMessages, (messageDiv) -> messageDiv.hide()

    if this.siteIsUpdatable()
      planChangeType = @checkedPlan.attr 'data-plan_change_type'
      planChangeType = 'in_trial_instant_upgrade' if planChangeType is 'in_trial_update' and this.skippingTrial()
      planChangeType = '' if planChangeType is 'skipping_trial' and !this.skippingTrial()
      _.each @processDetailsMessages, (messageDiv, type) =>
        this.updateProcessDetailsMessages(messageDiv) if planChangeType is type

  updateProcessDetailsMessages: (messagesDiv) ->
    _.each ['plan_title', 'plan_update_date'], (className) =>
      messagesDiv.find(".#{className}").html @checkedPlan.attr("data-#{className}")

    _.each ['plan_price', 'plan_update_price'], (className) =>
      text = if @checkedPlan.attr('data-vat')?
        "<strong>#{@checkedPlan.attr("data-#{className}_vat")}</strong> (including #{@checkedPlan.attr("data-vat")} VAT)"
      else
        @checkedPlan.attr("data-#{className}")
      messagesDiv.find(".#{className}").html text
    messagesDiv.show()
