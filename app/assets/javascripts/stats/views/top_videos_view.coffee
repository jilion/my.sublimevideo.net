class MSVStats.Views.TopVideosView extends Backbone.View
  template: JST['stats/templates/top_videos']

  initialize: ->
    this._listenToModelsEvents()

  events: ->
    'click a.play.active': '_prepareAndPlayVideo'
    'click a#video_loads': '_sortByLoads'
    'click a#video_views': '_sortByViews'
    'click a#show_more':   '_showMore'
    'click a#show_less':   '_showLess'

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(@options.period, 'change', this.render)
    this.listenTo(@options.videos, 'change', this.render)

  render: =>
    if MSVStats.videos.isReady()
      @$el.data().spinner.stop()

      @videos = MSVStats.videos
      @models = @videos.customModels()
      @$el.html(this.template(videos: @videos, models: @models))
      this.renderSparklines(@models)
      this.updateTitle()
    else
      @$el.empty()
      @$el.spin(spinOptions)

    this

  renderSparklines: (models) ->
    for video in models
      if video.isShowable()
        MSVStats.chartsHelper.sparkline($("#sparkline_#{video.cid}"), video.vvArray(),
          width:  '100%'
          height: '100%'
          lineColor: '#1ce937'
          fillColor: '#71bb93')

  updateTitle: ->
    title = switch MSVStats.videos.sortBy
            when 'vl' then 'loaded'
            when 'vv' then 'played'
    $('#top_videos_title').text("Most #{title} videos")

  #
  # PRIVATE
  #
  _prepareAndPlayVideo: (event) ->
    videoUid = $(event.currentTarget).attr("data-video-uid")
    MSVStats.playableVideoView.renderAndPlay(videoUid)

  _sortByLoads: (event) ->
    unless MSVStats.videos.sortBy is 'vl'
      $('#video_loads').text 'Sorting...'
      $('#video_loads').addClass ' spinner'
      MSVStats.videos.change(sortBy: 'vl')

    false

  _sortByViews: (event) ->
    unless MSVStats.videos.sortBy is 'vv'
      $('#video_views').text 'Sorting...'
      $('#video_views').addClass ' spinner'
      MSVStats.videos.change(sortBy: 'vv')

    false

  _showMore: ->
    $('#show_more').text 'Expanding...'
    $('#show_more').addClass 'spinner'
    MSVStats.videos.change(limit: 20)

    false

  _showLess: ->
    $('#show_less').text 'Reducing...'
    $('#show_less').addClass 'spinner'
    MSVStats.videos.change(limit: 5)

    false
