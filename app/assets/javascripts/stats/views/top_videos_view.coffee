class MSVStats.Views.TopVideosView extends Backbone.View
  template: JST['stats/templates/_top_videos']

  events:
    'click a.play':        'prepareAndPlayVideo'
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
      $(@el).show()
      $('#top_videos').data().spinner.stop()

      @videos = MSVStats.videos
      $(@el).html(this.template(videos: @videos))
      this.renderSparklines()
      this.updateTitle()

      return this
    else
      $(@el).hide()
      $('#top_videos').spin()
      return this

  renderSparklines: ->
    for video in MSVStats.videos.customModels()
      if video.isShowable()
        MSVStats.chartsHelper.sparkline $("#sparkline_#{video.id}"), video.vvArray(),
          width:  '100%'
          height: '100%'
          lineColor: '#1ce937'
          fillColor: '#71bb93'

  updateTitle: ->
    title = switch MSVStats.videos.sortBy
      when 'vl' then 'loaded'
      when 'vv' then 'viewed'
    $('#top_videos_title').text("Most #{title} videos")

  prepareAndPlayVideo: (event) ->
    videoID = event.target.id.match(/img-(.*)/)[1]
    MSVStats.playableVideoView.renderAndPlay(videoID)

  sortByLoads: ->
    unless MSVStats.videos.sortBy == 'vl'
      $('#video_loads').text 'Loads...' # TODO remove with design implementation
      $('#video_loads').addClass 'spinner'
      MSVStats.videos.change sortBy: 'vl'
  sortByViews: ->
    unless MSVStats.videos.sortBy == 'vv'
      $('#video_views').text 'Views...' # TODO remove with design implementation
      $('#video_views').addClass 'spinner'
      MSVStats.videos.change sortBy: 'vv'

  showMore: ->
    $('#show_more').text 'Show more...' # TODO remove with design implementation
    $('#show_more').addClass 'spinner'
    MSVStats.videos.change limit: 20

  showLess: ->
    $('#show_less').text 'Show less...' # TODO remove with design implementation
    $('#show_less').addClass 'spinner'
    MSVStats.videos.change limit: 5


