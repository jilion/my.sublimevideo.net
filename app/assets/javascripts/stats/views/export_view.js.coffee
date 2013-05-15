class MSVStats.Views.ExportView extends Backbone.View
  template: JST['stats/templates/export']

  initialize: ->
    this._listenToModelsEvents()

  events: ->
    'click button:enabled': '_export'

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)

  render: =>
    if MSVStats.period.get('type')?
      @site = MSVStats.site
      @$el.html(this.template(site: @site, period: @options.period))

    this

  #
  # PRIVATE
  #
  _export: ->
    if confirm("Once the CSV export is ready, you'll receive an email with a link to download it.")
      $.post '/stats/exports',
        stats_export:
          site_token: MSVStats.site.get('token')
          from: @options.period.startTime() / 1000
          to: @options.period.endTime() / 1000
      this.$('button').prop('disabled', true)
      this.$('button span').html("Processing...")
