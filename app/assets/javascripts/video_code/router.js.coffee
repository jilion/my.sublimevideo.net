class MSVVideoCode.Routers.BuilderRouter extends Backbone.Router
  initialize: (options) ->
    @sites             = options['sites']
    @selectedSiteToken = options['selectedSiteToken']

    this.initModels()
    this.initViews()
    new MySublimeVideo.UI.DependantInputs

    sublimevideo.load()
    sublimevideo.ready =>
      MSVVideoCode.previewView.render()

  initModels: ->
    MSVVideoCode.sites = new MySublimeVideo.Collections.Sites(@sites)
    MSVVideoCode.sites.select @selectedSiteToken

    MSVVideoCode.video     = new MySublimeVideo.Models.Video
    MSVVideoCode.sources   = new MySublimeVideo.Collections.Sources
    MSVVideoCode.poster    = new MySublimeVideo.Models.Image
    MSVVideoCode.thumbnail = new MySublimeVideo.Models.Thumbnail

    this.setTestAssets()

  setTestAssets: ->
    MSVVideoCode.poster.setDimensions(false, MSVVideoCode.testAssets['poster'], { width: 800, height: 450 })
    sources = []
    _.each MSVVideoCode.testAssets['sources'], (attributes) =>
      source = new MySublimeVideo.Models.Source(_.extend(attributes,
        currentMimeType: "video/#{attributes['format']}"
        video: MSVVideoCode.video))
      source.setDimensions(attributes['src'], { sourceWidth: 640, sourceHeight: 360, width: 640, height: 360, ratio: 360 / 640 })
      sources.push source
    MSVVideoCode.sources.reset sources

    # Lightbox specific models
    MSVVideoCode.thumbnail.setDimensions(false, MSVVideoCode.testAssets['thumbnail'], { width: 192, height: 108 })

    MSVVideoCode.video.set
      poster: MSVVideoCode.poster
      sources: MSVVideoCode.sources
      thumbnail: MSVVideoCode.thumbnail
      dataName: 'Midnight Sun'

    MSVVideoCode.video.setDefaultDataUID()

  clearTestAssets: ->
    MSVVideoCode.poster.reset()
    MSVVideoCode.thumbnail.reset()
    _.each MSVVideoCode.sources.models, (source) ->
      source.reset()

  initViews: ->
    MSVVideoCode.previewView = new MSVVideoCode.Views.Preview
      el: '#preview'

    MSVVideoCode.sourcesView = new MSVVideoCode.Views.Kit
      el: '#kit_selection'

    MSVVideoCode.sourcesView = new MSVVideoCode.Views.Sources
      el: '#video_sources'

    MSVVideoCode.settingsView = new MSVVideoCode.Views.Settings
      el: '#video_settings'

    MSVVideoCode.lightboxView = new MSVVideoCode.Views.Lightbox
      el: '#lightbox_settings'

    if $('.get_the_code').exists()
      MSVVideoCode.codeView = new MSVVideoCode.Views.Code
        el: '#video_code_form'
