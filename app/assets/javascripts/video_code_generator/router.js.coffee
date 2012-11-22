class MSVVideoCodeGenerator.Routers.BuilderRouter extends Backbone.Router
  initialize: (options) ->
    @sites             = options['sites']
    @selectedSiteToken = options['selectedSiteToken']
    @kit               = options['kit']

    this.initModels()
    this.initViews()
    sublimevideo.load()
    MSVVideoCodeGenerator.previewView.render()
    new MySublimeVideo.UI.DependantInputs

  initModels: ->
    MSVVideoCodeGenerator.sites = new MySublimeVideo.Collections.Sites(@sites)
    MSVVideoCodeGenerator.sites.select @selectedSiteToken

    MSVVideoCodeGenerator.video     = new MySublimeVideo.Models.Video
    MSVVideoCodeGenerator.sources   = new MySublimeVideo.Collections.Sources
    MSVVideoCodeGenerator.poster    = new MySublimeVideo.Models.Image
    MSVVideoCodeGenerator.thumbnail = new MySublimeVideo.Models.Thumbnail

    this.setTestAssets()

  setTestAssets: ->
    MSVVideoCodeGenerator.poster.setDimensions(false, MSVVideoCodeGenerator.testAssets['poster'], { width: 800, height: 450 })
    sources = []
    _.each MSVVideoCodeGenerator.testAssets['sources'], (attributes) =>
      source = new MySublimeVideo.Models.Source(_.extend(attributes,
        currentMimeType: "video/#{attributes['format']}"
        video: MSVVideoCodeGenerator.video))
      source.setDimensions(attributes['src'], { sourceWidth: 640, sourceHeight: 360, width: 640, height: 360, ratio: 360 / 640 })
      sources.push source
    MSVVideoCodeGenerator.sources.reset sources

    # Lightbox specific models
    MSVVideoCodeGenerator.thumbnail.setDimensions(false, MSVVideoCodeGenerator.testAssets['thumbnail'], { width: 192, height: 108 })

    MSVVideoCodeGenerator.video.set
      poster: MSVVideoCodeGenerator.poster
      sources: MSVVideoCodeGenerator.sources
      thumbnail: MSVVideoCodeGenerator.thumbnail
      dataName: 'Midnight Sun'

    MSVVideoCodeGenerator.video.setDefaultDataUID()

  clearTestAssets: ->
    MSVVideoCodeGenerator.poster.reset()
    MSVVideoCodeGenerator.thumbnail.reset()
    _.each MSVVideoCodeGenerator.sources.models, (source) ->
      source.reset()

  initViews: ->
    MSVVideoCodeGenerator.previewView = new MSVVideoCodeGenerator.Views.Preview
      el: '#preview'

    MSVVideoCodeGenerator.sourcesView = new MSVVideoCodeGenerator.Views.Kit
      el: '#kit_selection'

    MSVVideoCodeGenerator.sourcesView = new MSVVideoCodeGenerator.Views.Sources
      el: '#video_sources'

    MSVVideoCodeGenerator.settingsView = new MSVVideoCodeGenerator.Views.Settings
      el: '#video_settings'

    MSVVideoCodeGenerator.lightboxView = new MSVVideoCodeGenerator.Views.Lightbox
      el: '#lightbox_settings'

    if $('.get_the_code').exists()
      MSVVideoCodeGenerator.codeView = new MSVVideoCodeGenerator.Views.Code
        el: '#video_code_form'
