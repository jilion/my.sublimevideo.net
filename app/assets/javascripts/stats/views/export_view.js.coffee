class MSVStats.Views.ExportView extends Backbone.View
  template: JST['stats/templates/_export']

  events:
    'click button':'export'

  initialize: ->
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render
    @options.period.bind 'change', this.render

  render: =>
    if MSVStats.period.get('type')?
      @site = MSVStats.sites.selectedSite
      $(@el).html(this.template(site: @site, period: @options.period))
    this


  export: ->
    if confirm("We will processing your CSV export, once done you will receive an email with a link to download it. Let's go?")
      site = MSVStats.sites.selectedSite
      $.post '/stats/exports',
        stats_export:
          st: site.get('token')
          from: @options.period.startTime() / 1000
          to: @options.period.endTime() / 1000
      $(@el).find('button').attr('disabled', 'disabled')
      $(@el).find('button span').html("Processing...")
