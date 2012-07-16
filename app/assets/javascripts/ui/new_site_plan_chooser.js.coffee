#= require ./plan_chooser
#
# Plan update manager for new sites [/sites/new]
#
class MySublimeVideo.UI.NewSitePlanChooser extends MySublimeVideo.UI.PlanChooser
  constructor: ->
    @formType    = 'create'
    @hostnameDiv = jQuery('#site_hostname')
    @plans       = jQuery('#plan_fields')
    super

    this.setupSkipTrialObserver() if this.trialSkippable()

  setupSkipTrialObserver: ->
    @skipTrialCheckbox.on 'click', =>
      this.handlePlansDisplay(this.skippingTrial())

    this.handlePlansDisplay(this.skippingTrial())

  handlePlansDisplay: (show) ->
    if show then @plans.show() else @plans.hide()

  handlePlanChange: ->
    @hostnameDiv.attr 'required', !this.checkedPlanPriceIsZero()
    @badgedCheckbox.attr 'checked', 'checked' if @checkedPlan.attr('id') is 'plan_free'
    super

  handleBillingInfo: (show) ->
    super
    this.handleSubmitButtonDisplay(!this.skippingTrial() or this.checkedPlanPriceIsZero() or @billingInfoState is 'present')
