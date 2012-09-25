# TODO
#
class MySublimeVideo.UI.AddonsChooser
  # constructor: ->
  #   @processDetailsDiv      = $("#plan_#{@formType}_info")
  #   @badgedDiv              = $('#badged')
  #   @badgedCheckbox         = $('#site_badged')
  #   @skipTrialDiv           = $('#skip_trial')
  #   @skipTrialCheckbox      = $('#site_skip_trial')
  #   @billingInfoDiv         = $('#billing_info')
  #   @checkedPlan            = $('#plans input[type=radio][checked]')
  #   @billingInfoState       = @billingInfoDiv.attr 'data-state'
  #   @processDetailsMessages = {}

  #   this.setupProcessDetailsMessages()
  #   this.setupPlansObservers()

  # setupProcessDetailsMessages: =>
  #   _.each ['in_trial_downgrade_to_free', 'in_trial_upgrade', 'skipping_trial_free', 'skipping_trial_paid', 'upgrade', 'upgrade_from_free', 'delayed_upgrade', 'delayed_downgrade', 'delayed_change', 'delayed_downgrade_to_free'], (name) =>
  #     @processDetailsMessages[name] = $("#plan_#{name}_info")

  # setupPlansObservers: ->
  #   $('#plan_fields input[type=radio]').each (index, el) =>
  #     el = $(el)
  #     el.on 'click', =>
  #       @checkedPlan = el
  #       this.selectCheckboxWrappingBox()
  #       this.handlePlanChange()

  #   this.handlePlanChange() if @checkedPlan.exists()

  # selectCheckboxWrappingBox: ->
  #   $('#plans ul .select_box').removeClass 'active'
  #   @checkedPlan.parents('.select_box').addClass 'active'

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
