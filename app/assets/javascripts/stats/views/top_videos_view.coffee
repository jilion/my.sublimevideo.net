class MSVStats.Views.TopVideosView extends Backbone.View
  template: JST['stats/templates/top_videos']

  events:
    'click a.play.active': 'prepareAndPlayVideo'
    'click a#video_loads': 'sortByLoads'
    'click a#video_views': 'sortByViews'
    'click a#show_more':   'showMore'
    'click a#show_less':   'showLess'

  initialize: () ->
    @options.period.bind 'change', this.render
    @options.videos.bind 'change', this.render
    @options.videos.bind 'reset',  this.render
    this.render()

  render: =>
    if MSVStats.videos.isReady()
      $(@el).data().spinner.stop()

      @videos = MSVStats.videos
      @models = @videos.customModels()
      $(@el).html(this.template(videos: @videos, models: @models))
      this.renderSparklines(@models)
      this.updateTitle()

      return this
    else
      $(@el).empty();
      $(@el).spin(spinOptions)
      return this

  renderSparklines: (models) ->
    for video in models
      if video.isShowable()
        MSVStats.chartsHelper.sparkline $("#sparkline_#{video.cid}"), video.vvArray(),
          width:  '100%'
          height: '100%'
          lineColor: '#1ce937'
          fillColor: '#71bb93'

  updateTitle: ->
    title = switch MSVStats.videos.sortBy
      when 'vl' then 'loaded'
      when 'vv' then 'played'
    $('#top_videos_title').text("Most #{title} videos")

  prepareAndPlayVideo: (event) ->
    videoUid = $(event.currentTarget).attr("data-video-uid")
    MSVStats.playableVideoView.renderAndPlay(videoUid)

  sortByLoads: (event) ->
    unless MSVStats.videos.sortBy == 'vl'
      $('#video_loads').text 'Sorting...'
      $('#video_loads').addClass ' spinner'
      MSVStats.videos.change sortBy: 'vl'
    false

  sortByViews: (event) ->
    unless MSVStats.videos.sortBy == 'vv'
      $('#video_views').text 'Sorting...'
      $('#video_views').addClass ' spinner'
      MSVStats.videos.change sortBy: 'vv'
    false

  showMore: ->
    $('#show_more').text 'Expanding...' # TODO remove with design implementation
    $('#show_more').addClass 'spinner'
    MSVStats.videos.change limit: 20
    false

  showLess: ->
    $('#show_less').text 'Reducing...' # TODO remove with design implementation
    $('#show_less').addClass 'spinner'
    MSVStats.videos.change limit: 5
    false
