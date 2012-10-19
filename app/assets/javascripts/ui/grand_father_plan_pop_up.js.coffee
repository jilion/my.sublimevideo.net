class MySublimeVideo.UI.GrandFatherPlanPopUp
  constructor: (@textDiv) ->
    this.setupObservers()

  # Define a onClick observer for the link.
  #
  setupObservers: ->
    $('.grandfather_plan_link').on 'click', =>
      SublimeVideo.UI.Utils.openPopup
        class: 'popup'
        anchor: @textDiv

      false
