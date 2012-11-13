class MSVVideoCodeGenerator.Routers.BuilderRouter extends Backbone.Router
  initialize: (options) ->
    @sites             = options['sites']
    @selectedSiteToken = options['selectedSiteToken']
    @kit               = options['kit']

    this.initModels()
    this.initViews()
    sublimevideo.load()
    MSVVideoCodeGenerator.previewView.render()

  initModels: ->
    MSVVideoCodeGenerator.sites = new MySublimeVideo.Collections.Sites(@sites)
    MSVVideoCodeGenerator.sites.select @selectedSiteToken

    MSVVideoCodeGenerator.video = new MySublimeVideo.Models.Video

    this.setTestAssets()

    # Iframe embed specific models
    # MSVVideoCodeGenerator.iframe = new MSVVideoCodeGenerator.Models.Iframe

  setTestAssets: ->
    MSVVideoCodeGenerator.poster = new MySublimeVideo.Models.Image
      src: MSVVideoCodeGenerator.testAssets['poster']
    sources = []
    _.each MSVVideoCodeGenerator.testAssets['sources'], (attributes) =>
      source = new MySublimeVideo.Models.Source(_.extend(attributes,
        currentMimeType: "video/#{attributes['format']}"
        video: MSVVideoCodeGenerator.video))
      source.setDimensions(attributes['src'], { sourceWidth: 640, sourceHeight: 360, width: 640, height: 360, ratio: 360 / 640 })
      sources.push source
    MSVVideoCodeGenerator.sources = new MySublimeVideo.Collections.Sources(sources)

    MSVVideoCodeGenerator.video.set
      poster: MSVVideoCodeGenerator.poster
      sources: MSVVideoCodeGenerator.sources
      dataName: 'Midnight Sun'

    # Lightbox specific models
    MSVVideoCodeGenerator.thumbnail = new MySublimeVideo.Models.Thumbnail
      src: MSVVideoCodeGenerator.testAssets['thumbnail']

    MSVVideoCodeGenerator.video.set(testAssetsUsed: true)
    MSVVideoCodeGenerator.video.setDefaultDataUID()

  resetTestAssets: ->
    MSVVideoCodeGenerator.poster.reset()
    MSVVideoCodeGenerator.thumbnail.reset()
    _.each MSVVideoCodeGenerator.sources.models, (source) ->
      source.reset()

    MSVVideoCodeGenerator.video.set(testAssetsUsed: false)

  initViews: ->
    MSVVideoCodeGenerator.sourcesView = new MSVVideoCodeGenerator.Views.Sources
      el: '#video_sources'

    MSVVideoCodeGenerator.settingsView = new MSVVideoCodeGenerator.Views.Settings
      el: '#video_settings'

    # if $('#kit_settings_form').exists()
    #   $.get "/sites/#{@selectedSiteToken}/players/#{@kit['id']}.js"

    MSVVideoCodeGenerator.lightboxView = new MSVVideoCodeGenerator.Views.Lightbox
      el: '#lightbox_attributes'

    MSVVideoCodeGenerator.codeView = new MSVVideoCodeGenerator.Views.Code
      el: '#code'

    MSVVideoCodeGenerator.previewView = new MSVVideoCodeGenerator.Views.Preview
      el: '#preview'
