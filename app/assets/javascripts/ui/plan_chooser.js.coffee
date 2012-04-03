# The EmbedCode handle the popup opening and SSL switch for the embed code popup.
#
class MySublimeVideo.UI.PlanChooser
  constructor: ->
    @processDetailsDiv = jQuery("#plan_#{@formType}_info")
    @badgedDiv         = jQuery('#badged')
    @badgedCheckbox    = jQuery('#site_badged')
    @skipTrialDiv      = jQuery('#skip_trial')
    @skipTrialCheckbox = jQuery('#site_skip_trial')
    @billingInfoDiv    = jQuery('#billing_info')
    @checkedPlan       = jQuery('#plans input[type=radio][checked]')
    @billingInfoState  = @billingInfoDiv.attr 'data-state'

    this.setupPlansObservers()
    this.setupSkipTrialObserver() if this.siteIsInTrial()

  # This se
  setupPlansObservers: ->
    jQuery('#plans input[type=radio]').each (index, el)=>
      el = jQuery(el)
      el.on 'click', =>
        @checkedPlan = el
        this.selectCheckboxWrappingBox()
        this.handlePlanChange()

    this.handlePlanChange() if @checkedPlan?

  setupSkipTrialObserver: ->
    @skipTrialCheckbox.on 'click', =>
      this.handleBillingInfo(this.skippingTrial())

    this.handleBillingInfo(this.skippingTrial()) if @checkedPlan?

  selectCheckboxWrappingBox: ->
    jQuery('#plans ul .select_box').removeClass 'active'
    @checkedPlan.parents('.select_box').addClass 'active'

  handlePlanChange: ->
    if @badgedDiv?
      if !this.checkedPlanPriceIsZero()
        @badgedDiv.show()
      else
        @badgedDiv.hide()
        @badgedCheckbox.attr 'checked', 'checked'

    if this.siteIsInTrial()
      if this.checkedPlanPriceIsZero()
        @skipTrialDiv.hide()
        @skipTrialCheckbox.removeAttr 'checked'
      else
        @skipTrialDiv.show()

    planChangeAndIsNotFree = !(this.checkedPlanIsCurrentPlan() or this.checkedPlanPriceIsZero())
    this.handleBillingInfo(planChangeAndIsNotFree and ((!this.siteIsInTrial() and this.checkedPlanIsAnUpgrade()) or this.skippingTrial()))

  handleBillingInfo: (show) ->
    if show then @billingInfoDiv.show() else @billingInfoDiv.hide()
    this.handleProcessDetails()

  handleSubmitButtonDisplay: (show) ->
    if show then jQuery('#site_submit').show() else jQuery('#site_submit').hide()

  checkedPlanIsCurrentPlan: -> @formType is 'update' and !@checkedPlan.attr('data-plan_change_type')?
  checkedPlanIsAnUpgrade: -> @checkedPlan.attr('data-plan_change_type') is 'upgrade'
  checkedPlanPriceIsZero: ->
    (@checkedPlan.attr('data-plan_update_price')? and @checkedPlan.attr('data-plan_update_price') is "$0") or @checkedPlan.attr('data-plan_price') is "$0"

  siteIsInTrial: -> @skipTrialDiv?

  skippingTrial: -> this.siteIsInTrial() and @skipTrialDiv.is(':visible') and @skipTrialCheckbox.attr('checked')?

  priceWithVATText: (field) ->
    if @checkedPlan.attr('data-vat')?
      "<strong>#{@checkedPlan.attr("data-#{field}_vat")}</strong> (including #{@checkedPlan.attr("data-vat")} VAT)"
    else
      "<strong>#{@checkedPlan.attr("data-#{field}")}</strong>"
