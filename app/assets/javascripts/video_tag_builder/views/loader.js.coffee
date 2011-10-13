class MSVVideoTagBuilder.Views.Loader extends Backbone.View
  template: JST['templates/_sites_select']

  events:
    'change select': 'updateToken'

  initialize: ->
    @sites = @options.sites
    # _.bindAll this, 'render'
    # @model.bind 'change:token', this.renderSpecializedBox

    this.render()

  updateToken: (event) ->
    console.log('plop!')
    @sites.select(event.target.value)
    @model.set({ token: event.target.value })
    event.stopPropagation()
    false

  render: ->
    $(@el).html(this.template(sites: @sites))
    $(@el).show()

    this
