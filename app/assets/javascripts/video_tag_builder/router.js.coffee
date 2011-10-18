class MSVVideoTagBuilder.Routers.BuilderRouter extends Backbone.Router
  initialize: (options) ->
    this.initModels()
    this.initViews()
    sublimevideo.load()
    MSVVideoTagBuilder.codeView.render()

  initModels: ->
    MSVVideoTagBuilder.builder = new MSVVideoTagBuilder.Models.Builder

    MSVVideoTagBuilder.poster = new MSVVideoTagBuilder.Models.Image
    MSVVideoTagBuilder.sources = new MSVVideoTagBuilder.Collections.Sources([
      new MSVVideoTagBuilder.Models.Source(format: 'mp4', formatTitle: 'MP4', embedWidth: 852, embedHeight: 480, ratio: 480/852)
      new MSVVideoTagBuilder.Models.Source(format: 'mp4', formatTitle: 'MP4', quality: 'hd', isUsed: false)
      new MSVVideoTagBuilder.Models.Source(format: 'mp4', formatTitle: 'MP4', quality: 'mobile', isUsed: false)
      new MSVVideoTagBuilder.Models.Source(format: 'webmogg', formatTitle: 'WebM or Ogg', optional: true)
      new MSVVideoTagBuilder.Models.Source(format: 'webmogg', formatTitle: 'WebM or Ogg', optional: true, quality: 'hd', isUsed: false)
    ])

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

    MSVVideoTagBuilder.lightboxView = new MSVVideoTagBuilder.Views.Lightbox
      thumbnail: MSVVideoTagBuilder.thumbnail
      el: '#lightbox_attributes'

    MSVVideoTagBuilder.iframeEmbedView = new MSVVideoTagBuilder.Views.IframeEmbed
      model: MSVVideoTagBuilder.iframe
      el: '#iframe_embed_attributes'

    MSVVideoTagBuilder.posterView = new MSVVideoTagBuilder.Views.Poster
      model: MSVVideoTagBuilder.poster
      el: '#poster'

    MSVVideoTagBuilder.sourcesView = new MSVVideoTagBuilder.Views.Sources
      collection: MSVVideoTagBuilder.sources
      el: '#sources'

    new MSVVideoTagBuilder.Views.EmbedDimensions
      model: MSVVideoTagBuilder.sources.mp4Base()
      el: '#embed_dimensions'

    MSVVideoTagBuilder.codeView = new MSVVideoTagBuilder.Views.Code
      builder: MSVVideoTagBuilder.builder
      loader: MSVVideoTagBuilder.loader
      poster: MSVVideoTagBuilder.poster
      thumbnail: MSVVideoTagBuilder.thumbnail
      iframe: MSVVideoTagBuilder.iframe
      sources: MSVVideoTagBuilder.sources
      el: '#code'

    MSVVideoTagBuilder.previewView = new MSVVideoTagBuilder.Views.Preview
      el: '#preview'
