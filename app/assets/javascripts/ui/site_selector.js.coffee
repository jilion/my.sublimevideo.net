class MySublimeVideo.UI.SiteSelector
  constructor: (@options = {}) ->
    @select = @options.select
    this.setupObservers()

  setupObservers: ->
    @select.on 'change', =>
      href = location.href.replace("/#{@select.attr('data-token')}", "/#{@select.val()}")
      Turbolinks.visit(href)
