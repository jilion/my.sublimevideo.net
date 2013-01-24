class MySublimeVideo.UI.ExpandableItem
  constructor: (@el) ->
    @el.on 'click', (event) =>
      this.toggleExpandableBox(@el)
      false

  toggleExpandableBox: ($el) ->
    toggle = !$el.hasClass('expanded')
    $('.expanding_handler.expanded').removeClass('expanded')
    $('.expandable.expanded').removeClass('expanded')

    if toggle
      $el.toggleClass('expanded')
      $el.siblings('.expandable').toggleClass('expanded')
