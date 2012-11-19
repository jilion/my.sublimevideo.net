class MSVStats.Views.ExportView extends Backbone.View
  template: JST['stats/templates/_export']

  events:
    'click button:enabled':'export'

  initialize: ->
    @options.period.bind 'change', this.render

  render: =>
    if MSVStats.period.get('type')?
      @site = MSVStats.site
      $(@el).html(this.template(site: @site, period: @options.period))
    this


  export: ->
    if confirm("Once the CSV export is ready, you'll receive an email with a link to download it.")
      $.post '/stats/exports',
        stats_export:
          site_token: MSVStats.site.get('token')
          from: @options.period.startTime() / 1000
          to: @options.period.endTime() / 1000
      $(@el).find('button').attr('disabled', 'disabled')
      $(@el).find('button span').html("Processing...")
