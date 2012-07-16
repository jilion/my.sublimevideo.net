#= require ./plan_chooser
#
# Plan update manager for sites that are persisted (they can be in trial or not) [/sites/:token/plan/edit]
#
class MySublimeVideo.UI.PersistedSitePlanChooser extends MySublimeVideo.UI.PlanChooser
  constructor: ->
    @formType = 'update'
    super

  handleBillingInfo: (show) ->
    super
    this.handleSubmitButtonDisplay(!this.checkedPlanIsCurrentPlan() and (this.checkedPlanPriceIsZero() or this.siteIsUpdatable()))
