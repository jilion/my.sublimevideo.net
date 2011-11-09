class MSVStats.Views.TopVideosView extends Backbone.View
  template: JST['stats/templates/_top_videos']

  events:
    'click a.play':        'prepareAndPlayVideo'
    'click a#video_loads': 'sortByLoads'
    'click a#video_views': 'sortByViews'
    'click a#show_more':   'showMore'
    'click a#show_less':   'showLess'

  initialize: () ->
    @sortBy = 'vv'
    @count  = 5
    _.bindAll this, 'render'
    @options.period.bind 'change', this.render
    @options.videos.bind 'reset',  this.render
    this.render()

  render: ->
    if MSVStats.videos.isSamePeriod()
      $(@el).show()
      $('#top_videos').data().spinner.stop()

      @videos = MSVStats.videos
      $(@el).html(this.template(videos: @videos, sortBy: @sortBy, count: @count))
      this.renderSparklines()
      this.updateTitle()

      return this
    else
      $(@el).hide()
      $('#top_videos').spin()
      return this

  renderSparklines: ->
    for video in MSVStats.videos.models
      $("#sparkline_#{video.id}").sparkline video.get('vv_array'),
        width: '150px'
        height: '25px'

  updateTitle: ->
    title = switch @sortBy
      when 'vl' then 'loaded'
      when 'vv' then 'viewed'
    $('#top_videos_title').text("Most #{title} videos")

  prepareAndPlayVideo: (event) ->
    videoID = event.target.id.match(/img-(.*)/)[1]
    MSVStats.playableVideoView.renderAndPlay(videoID)

  sortByLoads: ->
    unless @sortBy == 'vl'
      @sortBy = 'vl'
      MSVStats.videos.fetch()

  sortByViews: ->
    unless @sortBy == 'vv'
      @sortBy = 'vv'
      MSVStats.videos.fetch()
      
  showMore: ->
    @count = 20
    MSVStats.videos.fetch()
    
  showLess: ->
    @count = 5
    MSVStats.videos.fetch()
      
  
