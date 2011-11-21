//= require prototype
//= require modernizr
//= require s2
//= require application

document.observe "dom:loaded", ->
  # Reproduce checkbox behavior for radio buttons for plans selection
  if $('plans') then new PlanUpdateManager()

class PlanUpdateManager
  constructor: ->
    @planUpdateInfoDiv = $('plan_upgrade_info')
    @planCreateInfoDiv = $('plan_create_info')
    @skipTrialDiv      = $('skip_trial')
    @skipTrialCheckbox = $('site_skip_trial')
    @billingInfosDiv   = $('billing_infos')
    @hostnameDiv       = $('site_hostname')
    @checkedPlan       = null
    @messages          = $H()

    this.setupMessages()
    this.setupPlanObservers()
    if @skipTrialCheckbox? then this.setupSkipTrialObserver()

  setupMessages: =>
    ['in_trial_downgrade_to_free', 'in_trial_update', 'in_trial_instant_upgrade', 'upgrade', 'upgrade_from_free', 'delayed_upgrade', 'delayed_downgrade', 'delayed_change', 'delayed_downgrade_to_free'].each (name) =>
      divName = "plan_#{name}_info"
      @messages.set(name, $(divName))

  setupPlanObservers: ->
    $$('#plans input[type=radio]').each (element) =>
      element.on 'click', (event) =>
        @checkedPlan = element
        select_box = element.up('.select_box')
        $$('#plans ul .select_box').invoke 'removeClassName', 'active'
        if select_box then select_box.addClassName 'active'
        this.handlePlanChange()

  setupSkipTrialObserver: ->
    @skipTrialCheckbox.on 'click', (event) =>
      this.handleBillingInfos(@skipTrialCheckbox.checked)

  handleBillingInfos: (show) ->
    billingInfosState = @billingInfosDiv.readAttribute 'data-state'
    $("billing_infos_#{billingInfosState}").show()
    if show
      @billingInfosDiv.show()
      if billingInfosState isnt 'present'
        @planUpdateInfoDiv.hide()
        $('site_submit').hide()
        if @planUpdateInfoDiv?
          @messages.each (pair) -> pair.value.hide()
        if @planCreateInfoDiv? then this.showPlanCreateInfo()
    else
      @billingInfosDiv.hide()
      $('site_submit').show()
      if @planUpdateInfoDiv? then this.showPlanUpdateInfo()
      if @planCreateInfoDiv? then this.showPlanCreateInfo()

  handlePlanChange: ->
    plan_price    = @checkedPlan.readAttribute('data-plan_price')
    price_is_zero = plan_price is "$0"

    # new site
    if @hostnameDiv? then @hostnameDiv.required = !price_is_zero

    # new site & plan change on trial site
    if @skipTrialDiv?
      if price_is_zero then @skipTrialDiv.hide() else @skipTrialDiv.show()

    this.handleBillingInfos(@checkedPlan.readAttribute('data-plan_change_type') is 'upgrade')

  updatePlanInfo_: (infoDiv) ->
    ['plan_title', 'plan_price', 'plan_price_vat', 'plan_update_price', 'plan_update_price_vat', 'plan_update_date'].each (className) =>
      infoDiv.select(".#{className}").invoke("update", @checkedPlan.readAttribute("data-#{className}"))
    infoDiv.show()

  showPlanCreateInfo: ->
    @planCreateInfoDiv.hide();
    if @checkedPlan.readAttribute('data-plan_price') isnt "$0" && @skipTrialCheckbox.checked
      this.updatePlanInfo_ @planCreateInfoDiv

  showPlanUpdateInfo: ->
    @messages.each (pair) -> pair.value.hide()

    planChangeType = @checkedPlan.readAttribute 'data-plan_change_type'
    if planChangeType is 'in_trial_update' && @skipTrialCheckbox.checked
      planChangeType = 'in_trial_instant_upgrade'

    @messages.each (pair) =>
      if planChangeType is pair.key
        this.updatePlanInfo_ pair.value

