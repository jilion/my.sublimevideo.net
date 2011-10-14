class MSVVideoTagBuilder.Views.Loader extends Backbone.View
  template: JST['templates/_sites_select']

  events:
    'change select': 'updateToken'

  initialize: ->
    @sites = @options.sites

    _.bindAll this, 'render'
    # @model.bind 'change:token', this.renderSpecializedBox

    this.render()

  #
  # EVENTS
  #
  updateToken: (event) ->
    @sites.select(event.target.value)
    @model.set({ token: event.target.value })
    # MSVVideoTagBuilder.builderRouter.navigate("sites/#{event.target.value}/video/new", false)


  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(sites: @sites))
    $(@el).show()

    this
