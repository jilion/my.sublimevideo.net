#= require application
#= require highcharts/prototype-adapter
#= require highcharts/highcharts

document.observe "dom:loaded", ->
  if $('plans')
    if $('new_site')
      new NewSitePlanUpdateManager()
    else
      new PersistedSitePlanUpdateManager()

class PlanUpdateManager
  constructor: ->
    @processDetailsDiv = $("plan_#{@formType}_info")
    @skipTrialDiv      = $('skip_trial')
    @skipTrialCheckbox = $('site_skip_trial')
    @billingInfoDiv    = $('billing_info')
    @checkedPlan       = null
    @billingInfoState  = @billingInfoDiv.readAttribute 'data-state'

    this.setupPlansObservers()
    this.setupSkipTrialObserver() if this.siteIsInTrial()

  setupPlansObservers: ->
    $$('#plans input[type=radio]').each (element) =>
      element.on 'click', (event) =>
        @checkedPlan = element
        this.selectCheckboxWrappingBox()
        this.handlePlanChange()

  setupSkipTrialObserver: ->
    @skipTrialCheckbox.on 'click', (event) =>
      this.handleBillingInfo(this.skippingTrial())

  selectCheckboxWrappingBox: ->
    $$('#plans ul .select_box').invoke 'removeClassName', 'active'
    @checkedPlan.up('.select_box').addClassName 'active'

  handlePlanChange: ->
    planChangeAndIsNotFree = !this.checkedPlanIsCurrentPlan() and !this.checkedPlanPriceIsZero()
    if this.siteIsInTrial()
      if planChangeAndIsNotFree
        @skipTrialDiv.show()
      else
        @skipTrialDiv.hide()
        @skipTrialCheckbox.checked = false
    this.handleBillingInfo(planChangeAndIsNotFree and ((!this.siteIsInTrial() and this.checkedPlanIsAnUpgrade()) or this.skippingTrial()))

  handleBillingInfo: (show) ->
    if show then @billingInfoDiv.show() else @billingInfoDiv.hide()
    this.handleProcessDetails()

  handleSubmitButtonDisplay: (show) ->
    if show then $('site_submit').show() else $('site_submit').hide()

  checkedPlanIsCurrentPlan: -> @formType is 'update' and !@checkedPlan.readAttribute('data-plan_change_type')?
  checkedPlanIsAnUpgrade: -> @checkedPlan.readAttribute('data-plan_change_type') is 'upgrade'
  checkedPlanPriceIsZero: ->
    (@checkedPlan.readAttribute('data-plan_update_price')? and @checkedPlan.readAttribute('data-plan_update_price') is "$0") or @checkedPlan.readAttribute('data-plan_price') is "$0"

  siteIsInTrial: -> @skipTrialDiv?

  skippingTrial: -> this.siteIsInTrial() and @skipTrialDiv.visible() and @skipTrialCheckbox.checked

  priceWithVATText: (field) ->
    if @checkedPlan.readAttribute("data-vat")?
      "<strong>#{@checkedPlan.readAttribute("data-#{field}_vat")}</strong> (including #{@checkedPlan.readAttribute("data-vat")} VAT)"
    else
      "<strong>#{@checkedPlan.readAttribute("data-#{field}")}</strong>"


# Plan update manager for new sites [/sites/new]
class NewSitePlanUpdateManager extends PlanUpdateManager
  constructor: ->
    @formType    = 'create'
    @hostnameDiv = $('site_hostname')
    super

  handlePlanChange: ->
    @hostnameDiv.required = !this.checkedPlanPriceIsZero()
    super

  handleBillingInfo: (show) ->
    super
    this.handleSubmitButtonDisplay(this.checkedPlanPriceIsZero() or !this.skippingTrial() or @billingInfoState is 'present')

  handleProcessDetails: ->
    if !this.checkedPlanPriceIsZero() and this.skippingTrial() and @billingInfoState is 'present'
      @processDetailsDiv.select(".plan_price").invoke "update", this.priceWithVATText('plan_price')
      @processDetailsDiv.show()
    else
      @processDetailsDiv.hide()


# Plan update manager for sites that are persisted (they can be in trial or not) [/sites/:token/plan/edit]
class PersistedSitePlanUpdateManager extends PlanUpdateManager
  constructor: ->
    @formType = 'update'
    @processDetailsMessages = $H()
    super
    this.setupProcessDetailsMessages()

  setupProcessDetailsMessages: =>
    ['in_trial_downgrade_to_free', 'in_trial_update', 'in_trial_instant_upgrade', 'upgrade', 'upgrade_from_free', 'delayed_upgrade', 'delayed_downgrade', 'delayed_change', 'delayed_downgrade_to_free'].each (name) =>
      @processDetailsMessages.set(name, $("plan_#{name}_info"))

  handleBillingInfo: (show) ->
    super
    this.handleSubmitButtonDisplay(this.checkedPlanPriceIsZero() or (!this.checkedPlanIsCurrentPlan() and this.siteIsUpdatable()))

  siteIsUpdatable: ->
    (this.siteIsInTrial() and (!this.skippingTrial() or @billingInfoState is 'present')) or (!this.siteIsInTrial() and (!this.checkedPlanIsAnUpgrade() or @billingInfoState is 'present'))

  handleProcessDetails: ->
    @processDetailsMessages.each (pair) -> pair.value.hide()

    if !this.checkedPlanIsCurrentPlan() and this.siteIsUpdatable()
      planChangeType = @checkedPlan.readAttribute 'data-plan_change_type'
      planChangeType = 'in_trial_instant_upgrade' if planChangeType is 'in_trial_update' and this.skippingTrial()

      @processDetailsMessages.each (pair) =>
        this.updateProcessDetailsMessages(pair.value) if planChangeType is pair.key

  updateProcessDetailsMessages: (messagesDiv) ->
    ['plan_title', 'plan_update_date'].each (className) =>
      messagesDiv.select(".#{className}").invoke("update", @checkedPlan.readAttribute("data-#{className}"))

    ['plan_price', 'plan_update_price'].each (className) =>
      text = if @checkedPlan.readAttribute("data-vat")?
        "<strong>#{@checkedPlan.readAttribute("data-#{className}_vat")}</strong> (including #{@checkedPlan.readAttribute("data-vat")} VAT)"
      else
        @checkedPlan.readAttribute("data-#{className}")
      messagesDiv.select(".#{className}").invoke("update", text)
    messagesDiv.show()
