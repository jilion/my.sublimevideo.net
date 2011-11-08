class MSVStats.Views.TopVideosView extends Backbone.View
  template: JST['stats/templates/_top_videos']

  initialize: () ->
    _.bindAll this, 'render'
    @options.period.bind 'change', this.render
    @options.videos.bind 'reset',  this.render
    this.render()

  render: ->
    if MSVStats.videos.isSamePeriod()
      $(@el).show()
      $('#top_videos').data().spinner.stop()

      @videos = MSVStats.videos
      $(@el).html(this.template(videos: @videos))

      return this
    else
      $(@el).hide()
      $('#top_videos').spin()
      return this

