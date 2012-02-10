class MSVStats.Views.PlayableVideoView extends Backbone.View
  template: JST['stats/templates/_playable_video']

  renderAndPlay: (videoID) =>
    if (video = MSVStats.videos.get(videoID))?
      $(@el).html(this.template(video: video))
      sublimevideo.prepareAndPlay("playable_video_#{video.id}")

    this
