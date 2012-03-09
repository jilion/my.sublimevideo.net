class MSVVideoCodeGenerator.Views.IframeEmbed extends Backbone.View
  template: JST['video_code_generator/templates/_iframe_embed']

  events:
    'change #iframe_src': 'updateSrc'
    'change #site_select': 'selectSite'

  initialize: ->
    @loader = @options.loader
    @sites  = @options.sites

    _.bindAll this, 'render'
    @loader.bind 'change:site', this.render

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @model.set(src: event.target.value)

  selectSite: (event) ->
    @sites.select event.target.value
    @loader.set(site: @sites.selectedSite)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html this.template(loader: @loader, iframe: @model, sites: @sites)
    $(@el).show()

    this

  hide: ->
    $(@el).hide()
