class MSVVideoTagBuilder.Views.Lightbox extends Backbone.View
  template: JST['video_tag_builder/templates/_lightbox']

  events:
    'keyup #thumb_src': 'updateSrc'
    'change #thumb_src': 'updateSrc'
    'keyup #thumb_width': 'updateThumbWidth'
    'click #thumb_magnifying_glass': 'updateMagnifyingGlass'
    'click .reset': 'resetDimensions'

  initialize: ->
    @thumbnail = @options.thumbnail

    _.bindAll this, 'render', 'preloadSrcAndUpdateExtraVisibility', 'renderWidth', 'renderHeight'
    @thumbnail.bind 'change:src', this.preloadSrcAndUpdateExtraVisibility
    @thumbnail.bind 'change:thumbWidth', this.renderWidth
    @thumbnail.bind 'change:thumbHeight', this.renderHeight
    # @thumbnail.bind 'change', this.renderPreview

  updateSrc: (event) ->
    @thumbnail.set(src: event.target.value)

  updateThumbWidth: (event) ->
    @thumbnail.updateDimensionsWithWidth(event.target.value)

  updateMagnifyingGlass: (event) ->
    @thumbnail.set(magnifyingGlass: event.target.checked)

  resetDimensions: (event) ->
    @thumbnail.updateDimensionsWithWidth(@thumbnail.get('width'))
    event.stopPropagation()
    false

  renderWidth: ->
    $("#thumb_width").attr(value: @thumbnail.get('thumbWidth'))

  renderHeight: ->
    $("#thumb_height").attr(value: @thumbnail.get('thumbHeight'))

  preloadSrcAndUpdateExtraVisibility: =>
    if @thumbnail.srcIsUrl()
      @thumbnail.preloadSrc()
      $('.extra').show()
    else
      $('.extra').hide()

  render: ->
    $(@el).html(this.template(thumbnail: @thumbnail))
    $(@el).show()

    this

  hide: ->
    $(@el).hide()