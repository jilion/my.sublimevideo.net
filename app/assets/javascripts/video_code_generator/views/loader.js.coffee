class MSVVideoCodeGenerator.Views.Loader extends Backbone.View
  template: JST['../templates/_site_select_title']

  events:
    'change select': 'updateToken'

  initialize: ->
    @sites = @options.sites

    _.bindAll this, 'render'

    this.render() if @sites

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
