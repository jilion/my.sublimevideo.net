class MSVVideoTagBuilder.Views.Sources extends Backbone.View
  template: JST['video_tag_builder/templates/_sources']

  events:
    'change .source':       'updateSrc'
    'click .use_source':    'updateIsUsed'
    'click #start_with_hd': 'updateStartWithHd'

  initialize: ->
    _.bindAll this, 'render', 'toggleStartWithHdBox', 'toggleSrcBox', 'renderEmbedWidth', 'renderEmbedHeight'
    @collection.bind 'change:src',    this.toggleStartWithHdBox
    @collection.bind 'change:isUsed', this.toggleSrcBox
    # @collection.bind 'change:isUsed', this.toggleStartWithHdBox
    @collection.bind 'change:width',  this.renderEmbedWidth
    @collection.bind 'change:height', this.renderEmbedHeight

    this.render()

  #
  # EVENTS
  #
  updateSrc: (event) ->
    @collection.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).setSrc(event.target.value)
    this.scrollToEl()

  updateIsUsed: (event) ->
    @collection.byFormatAndQuality(this.getSourceAndQuality(event.target.id)).set(isUsed: event.target.checked)

  updateStartWithHd: (event) ->
    MSVVideoTagBuilder.builder.set(startWithHd: event.target.checked)

  #
  # BINDINGS
  #
  render: ->
    $(@el).html(this.template(sources: @collection))

    this

  toggleStartWithHdBox: ->
    if @collection.hdPresent()
      $("#start_with_hd_box}").show()
    else
      $("#start_with_hd_box}").hide()

  toggleSrcBox: ->
    _.each @collection.allNonBase(), (source) ->
      srcBox = this.$("##{source.formatQuality()}_src_box")
      if source.get('isUsed') then srcBox.show() else srcBox.hide()
    this.toggleStartWithHdBox()
    this.scrollToEl()

  renderEmbedWidth: ->
    $("#embed_width").attr(value: @collection.mp4Base().get('embedWidth'))
    this.scrollToEl()

  renderEmbedHeight: ->
    $("#embed_height").attr(value: @collection.mp4Base().get('embedHeight'))
    this.scrollToEl()

  #
  # PRIVATE
  #
  getSourceAndQuality: (id) ->
    _.first(id.split('_'), 2)

  scrollToEl: ->
    $(window).scrollTop($(@el).position().top)
