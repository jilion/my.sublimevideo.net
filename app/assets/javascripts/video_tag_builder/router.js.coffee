class MSVVideoTagBuilder.Routers.BuilderRouter extends Backbone.Router
  initialize: (options) ->
    this.initModels()
    this.initViews()

  initModels: ->
    MSVVideoTagBuilder.builder = new MSVVideoTagBuilder.Models.StandardBuilder
    MSVVideoTagBuilder.builder.setup()

    MSVVideoTagBuilder.loader = new MSVVideoTagBuilder.Models.Loader

    MSVVideoTagBuilder.poster = new MSVVideoTagBuilder.Models.Image
    MSVVideoTagBuilder.sources = new MSVVideoTagBuilder.Collections.Sources([
      new MSVVideoTagBuilder.Models.Source(format: 'mp4', formatTitle: 'MP4')
      new MSVVideoTagBuilder.Models.Source(format: 'mp4', formatTitle: 'MP4', quality: 'hd', qualityTitle: 'HD')
      new MSVVideoTagBuilder.Models.Source(format: 'mp4', formatTitle: 'MP4', quality: 'mobile')
      new MSVVideoTagBuilder.Models.Source(format: 'webm_ogg', formatTitle: 'WebM or Ogg')
      new MSVVideoTagBuilder.Models.Source(format: 'webm_ogg', formatTitle: 'WebM or Ogg', quality: 'hd', qualityTitle: 'HD')
    ])

    MSVVideoTagBuilder.video = new MSVVideoTagBuilder.Models.Video
      poster: MSVVideoTagBuilder.poster
      sources: MSVVideoTagBuilder.sources

    # Lightbox specific models
    MSVVideoTagBuilder.thumbnail = new MSVVideoTagBuilder.Models.Thumbnail

    # Iframe embed specific models
    MSVVideoTagBuilder.iframe = new MSVVideoTagBuilder.Models.Iframe

  initViews: ->
    new MSVVideoTagBuilder.Views.VideoEmbedTypeSelector
      model: MSVVideoTagBuilder.builder
      el: '#video_embed_type_selector'

    new MSVVideoTagBuilder.Views.Loader
      model: MSVVideoTagBuilder.loader
      sites: MSVVideoTagBuilder.sites
      el: '#site_selector'

    new MSVVideoTagBuilder.Views.StandardAttributes
      el: '#standard_attributes'

    MSVVideoTagBuilder.lightboxView = new MSVVideoTagBuilder.Views.Lightbox
      thumbnail: MSVVideoTagBuilder.thumbnail
      el: '#lightbox_attributes'

    MSVVideoTagBuilder.iframeEmbedView = new MSVVideoTagBuilder.Views.IframeEmbed
      model: MSVVideoTagBuilder.iframe
      el: '#iframe_embed_attributes'
