class MSVVideoTagBuilder.Views.Lightbox extends Backbone.View
  template: JST['video_tag_builder/templates/_lightbox']

  events:
    'change #thumb_src':             'updateSrc'
    'change #thumb_width':           'updateThumbWidth'
    'click #thumb_magnifying_glass': 'updateMagnifyingGlass'
    'click .reset':                  'resetThumbDimensions'

  initialize: ->
    @thumbnail = @options.thumbnail

    _.bindAll this, 'render', 'renderExtra', 'renderThumbWidth', 'renderThumbHeight'
    @thumbnail.bind 'change:src',         this.renderExtra
    @thumbnail.bind 'change:thumbWidth',  this.renderThumbWidth
    @thumbnail.bind 'change:thumbHeight', this.renderThumbHeight

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @thumbnail.setAndPreloadSrc(event.target.value)

  updateThumbWidth: (event) ->
    event.target.value = parseInt(event.target.value)
    @thumbnail.setThumbWidth(event.target.value)

  updateMagnifyingGlass: (event) ->
    @thumbnail.set(magnifyingGlass: event.target.checked)

  resetThumbDimensions: (event) ->
    @thumbnail.setThumbWidth(@thumbnail.get('width'))

    event.stopPropagation()
    false

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(thumbnail: @thumbnail))
    $(@el).show()
    this.scrollToEl()

    this

  hide: ->
    $(@el).hide()

  renderExtra: ->
    extraDiv = $('.extra')
    if @thumbnail.srcIsUrl() then extraDiv.show() else extraDiv.hide()
    this.scrollToEl()

  renderThumbWidth: ->
    $("#thumb_width").attr(value: @thumbnail.get('thumbWidth'))
    this.scrollToEl()

  renderThumbHeight: ->
    $("#thumb_height").attr(value: @thumbnail.get('thumbHeight'))
    this.scrollToEl()

  scrollToEl: ->
    $(window).scrollTop($(@el).position().top)
