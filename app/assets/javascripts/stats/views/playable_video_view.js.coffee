class MSVStats.Views.PlayableVideoView extends Backbone.View
  template: JST['stats/templates/_playable_video']

  renderAndPlay: (videoID) =>
    if (video = MSVStats.videos.getByCid(videoID))?
      $(@el).html(this.template(video: video))
      sublime.prepare "playable_video_#{video.cid}_link", (lightbox) -> lightbox.open()

    this
