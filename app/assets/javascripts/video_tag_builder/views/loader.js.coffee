class MSVVideoTagBuilder.Views.Loader extends Backbone.View
  template: JST['templates/_sites_select']

  events:
    'change select': 'updateToken'

  initialize: ->
    @sites = @options.sites

    _.bindAll this, 'render'

    this.render()

  #
  # EVENTS
  #
  updateToken: (event) ->
    @sites.select(event.target.value)
    @model.set({ token: event.target.value })
    @model.set({ hostname: event.target.options[event.target.selectedIndex].innerText })

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(sites: @sites))

    this
