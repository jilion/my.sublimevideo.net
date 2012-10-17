class MySublimeVideo.UI.KitEditor
  constructor: ->
    this.setupInputsObservers()

  setupInputsObservers: ->
    $('input[type=range][data-addon]').each (index, el) =>
      $el = $(el)
      $el.on 'change', =>
        this.updateValueDisplayer($el)

  updateValueDisplayer: ($el) ->
    $("##{$el.attr('id')}_value").text Math.round($el.val() * 100) / 100
