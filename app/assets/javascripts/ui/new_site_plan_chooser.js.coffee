#= require ./plan_chooser
#
# Plan update manager for new sites [/sites/new]
#
class MySublimeVideo.UI.NewSitePlanChooser extends MySublimeVideo.UI.PlanChooser
  constructor: ->
    @formType    = 'create'
    @hostnameDiv = jQuery('#site_hostname')
    @plans       = jQuery('#plans')
    @trialNote   = jQuery('#trial_note')
    super

    this.setupSkipTrialObserver() if this.trialSkippable()

  setupSkipTrialObserver: ->
    @skipTrialCheckbox.on 'click', =>
      this.handlePlansDisplay(this.skippingTrial())
      this.handlePlanChange() if @checkedPlan.exists()

    this.handlePlansDisplay(this.skippingTrial())

  handlePlansDisplay: (show) ->
    if show
      @plans.show()
      @trialNote.hide()
    else
      @plans.hide()
      @trialNote.show()

  handlePlanChange: ->
    @hostnameDiv.attr 'required', !this.checkedPlanPriceIsZero()
    @badgedCheckbox.attr 'checked', 'checked' if @checkedPlan.attr('id') is 'plan_free'
    super
    this.handleBillingInfo(false) unless this.skippingTrial()

  handleBillingInfo: (show) ->
    super
    this.handleSubmitButtonDisplay(!this.skippingTrial() or this.checkedPlanPriceIsZero() or @billingInfoState is 'present')
