class MSVStats.Views.TopVideosView extends Backbone.View
  template: JST['stats/templates/_top_videos']

  events:
    'click a.play':        'prepareAndPlayVideo'
    'click a#video_loads': 'sortByLoads'
    'click a#video_views': 'sortByViews'
    'click a#show_more':   'showMore'
    'click a#show_less':   'showLess'

  initialize: () ->
    _.bindAll this, 'render'
    @options.period.bind 'change', this.render
    @options.videos.bind 'reset',  this.render
    this.render()

  render: ->
    if MSVStats.videos.isSamePeriod() && MSVStats.videos.total?
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
    for video in MSVStats.videos.models
      $("#sparkline_#{video.id}").sparkline video.get('vv_array').slice(0,60),
        width: '150px'
        height: '25px'
        lineColor: '#0046ff'
        fillColor: '#0046ff'

  updateTitle: ->
    title = switch MSVStats.videos.sortBy
      when 'vl' then 'loaded'
      when 'vv' then 'viewed'
    $('#top_videos_title').text("Most #{title} videos")

  prepareAndPlayVideo: (event) ->
    videoID = event.target.id.match(/img-(.*)/)[1]
    MSVStats.playableVideoView.renderAndPlay(videoID)

  sortByLoads: ->
    MSVStats.videos.change sortBy: 'vl' unless MSVStats.videos.sortBy == 'vl'
  sortByViews: ->
    MSVStats.videos.change sortBy: 'vv' unless MSVStats.videos.sortBy == 'vv'
      
  showMore: -> MSVStats.videos.change limit: 20
  showLess: -> MSVStats.videos.change limit: 5
      
  
