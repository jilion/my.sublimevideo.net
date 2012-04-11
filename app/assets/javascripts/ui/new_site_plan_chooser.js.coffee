# Plan update manager for new sites [/sites/new]
#
class MySublimeVideo.UI.NewSitePlanChooser extends MySublimeVideo.UI.PlanChooser
  constructor: ->
    @formType    = 'create'
    @hostnameDiv = jQuery('#site_hostname')
    super

  handlePlanChange: ->
    @hostnameDiv.attr 'required', !this.checkedPlanPriceIsZero()
    super

  handleBillingInfo: (show) ->
    super
    this.handleSubmitButtonDisplay(this.checkedPlanPriceIsZero() or !this.skippingTrial() or @billingInfoState is 'present')

  handleProcessDetails: ->
    if @processDetailsDiv.exists()
      if !this.checkedPlanPriceIsZero() and this.skippingTrial() and @billingInfoState is 'present'
        @processDetailsDiv.find('.plan_price').html this.priceWithVATText('plan_price')
        @processDetailsDiv.show()
      else
        @processDetailsDiv.hide()
