class MSVVideoTagBuilder.Views.Preview extends Backbone.View
  template: JST['video_tag_builder/templates/_preview']

  initialize: ->
    @builder   = @options.builder
    @poster    = @options.poster
    @thumbnail = @options.thumbnail
    @sources   = @options.sources

    _.bindAll this, 'render'
    @builder.bind   'change', this.render
    @poster.bind    'change', this.render
    @thumbnail.bind 'change', this.render
    @sources.bind   'change', this.render

  #
  # BINDINGS
  #
  render: ->
    if _.any(@sources.models, (source) -> source.srcIsUrl())
      sublimevideo.unprepare($('video').get(0)) if $('video').length

      attributes =
        poster: @poster
        sources: @sources
        width: @sources.mp4Normal().get('embedWidth')
        height: @sources.mp4Normal().get('embedHeight')

      switch MSVVideoTagBuilder.builder.get('builderClass')
        when 'lightbox'
          lightbox_attributes =
            thumbnail: @thumbnail
          attributes = $.extend({}, attributes, lightbox_attributes)
          @video = new MSVVideoTagBuilder.Models.VideoLightbox(attributes)
        else
          @video = new MSVVideoTagBuilder.Models.Video(attributes)

      $(@el).html(this.template(video: @video))

      sublimevideo.prepare($('video').get(0))

    this
