class MSVStats.Views.SitesSelectTitleView extends Backbone.View
  template: JST['_sites_select_title']

  events:
    'change select': 'updatePage'

  initialize: ->
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render

    this.render()

  render: =>
    $(@el).html(this.template(sites: @options.sites, statsRouter: MSVStats.statsRouter))
    this

  updatePage: (event) ->
    selectedToken = this.$('select').val()
    MSVStats.statsRouter.navigate("#{selectedToken}", true)
