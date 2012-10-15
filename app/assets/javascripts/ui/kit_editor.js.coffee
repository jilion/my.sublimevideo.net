class MySublimeVideo.UI.KitEditor
  constructor: (@form) ->
    this.setupInputsObservers()

  setupInputsObservers: ->
    @form.find('input[type=range]').each (index, el) =>
      $el = $(el)
      $el.on 'change', =>
        this.updateValueDisplayer($el)

  updateValueDisplayer: ($el) ->
    $("##{$el.attr('id')}_value").text Math.round($el.val() * 100) / 100
