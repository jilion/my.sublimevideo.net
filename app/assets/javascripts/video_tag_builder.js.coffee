#= require jquery
#= require jquery_ujs
#= require underscore
#= require backbone
#= require video-size-checker/sublimevideo-size-checker.min.js
#= require spin/jquery.spin

#= require ./base
#= require_self
#= require_tree ./video_tag_builder

window.MSVVideoTagBuilder =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

# document.observe 'dom:loaded', ->
#   videoTagBuilder = new VideoTagBuilder()

class VideoTagBuilder
  # constructor: (poster_id = 'poster', sources_class = 'video_src', keep_video_ratio = 'keep_video_ratio') ->
  #   @poster           = $(poster_id)
  #   @sources          = $$(".#{sources_class}")
  #   @keep_video_ratio = $(keep_video_ratio)
  # 
  #   # The <video> element generated from the settings provided by the user
  #   @video = null
  # 
  #   # The <video> element classes, 'sublime' by default
  #   @video_classes = 'sublime'
  # 
  #   # Final video size
  #   @video_dimensions = { width: null, height: null }
  # 
  #   sublimevideo.load()
  #   sublimevideo.ready =>
  #     this.setupObservers()

  # setupObservers: ->
  #   this.setupPosterObserver()
  #   this.setupSourcesObservers()
  #   this.setupDimensionsObservers()
  #   this.setupRatioKeeperObserver()
  # 
  # setupPosterObserver: ->
  #   @poster.observe 'keyup', (event) =>
  #     this.updateLivePreviewAndDisplayCode() if this.urlHasChanged event.target
  #   , false
  # 
  # setupSourcesObservers: ->
  #   @sources.each (source_input) =>
  #     source_input.observe 'keyup', (event) =>
  #       this.updateLivePreviewAndDisplayCode() if this.urlHasChanged event.target
  #     , false
  # 
  # setupDimensionsObserver: ->
  #   @sources[0].observe 'keyup', (event) =>
  #     this.setVideoDimensionsToInputFields event.target.value if this.urlHasChanged event.target
  #   , false
  # 
  #   ['width', 'height'].each (dimension) =>
  #     $("final_#{dimension}").observe 'keyup', (event) =>
  #       @video_dimensions[dimension] = event.target.value
  #       if not /\d+/.test @video_dimensions[dimension]
  #         event.target.value = @video_dimensions[dimension] = null
  #       else if keepRatio
  #         this.updateDimensionField this.oppositeDimension(dimension), @video_dimensions[dimension]
  #       this.updateLivePreviewAndDisplayCode()
  #     , false
  # 
  # setupRatioKeeperObserver: ->
  #   @keep_video_ratio.observe 'click', (event) =>
  #     # If the "keep ratio" check box has been checked, reset the right ratio to the current final dimensions
  #     if keepRatio
  #       this.updateDimensionField 'height', @video_dimensions['width']
  #       this.updateLivePreviewAndDisplayCode()
  # 
  # keepRatio: ->
  #   @keep_video_ratio.checked?

  oppositeDimension: (dimension) ->
    if dimension == 'width' then 'height' else 'width'

  urlHasChanged: (input) ->
    if (!input.getAttribute('data-last_url')? and input.value != "") or input.getAttribute('data-last_url') != input.value
      input.setAttribute('data-last_url', input.value);
      true
    else
      false

  updateLivePreviewAndDisplayCode: ->
    this.rebuildVideo()

  rebuildVideo: ->
    [poster, dimensions, sources] = [$('poster').value, [@video_dimensions['width'] or 300, @video_dimensions['height'] or 200], []]
    @sources.each (input) =>
      if this.isUrl input.value
        sources.push new Element('source', { src: input.value })

    @video = new Element 'video',
      id: 'live_preview_video'
      className: @video_classes
      poster: poster
      width: dimensions[0]
      height: dimensions[1]
      preload: 'none'
    sources.each (source) =>
      @video.insert source

  updateLivePreview: ->
    if $('live_preview_video')
      sublimevideo.unprepare 'live_preview_video'
      $('live_preview_video').remove()

    [poster, dimensions, sources] = [$('poster').value, [@video_dimensions['width'] or 300, @video_dimensions['height'] or 200], []]
    $$('.video_src').each (input) =>
      source = $(input.id).value
      if source != '' then sources.push new Element('source', { src: source }) if this.isUrl source

    @video = new Element 'video',
      id: 'live_preview_video'
      className: 'sublime'
      poster: poster
      width: dimensions[0]
      height: dimensions[1]
      preload: 'none'
    sources.each (source) =>
      @video.insert source

    if @video.height > 0 then $('live_preview_video_wrap').setStyle({ height: "#{@video.height}px" })
    $('live_preview_video_wrap').insert @video

    sublimevideo.prepare 'live_preview_video'

    $('video_tag_code').update "<video class=\"sublime\" poster=\"#{poster}\" width=\"#{dimensions[0]}\" height=\"#{dimensions[1]}\" preload=\"none\">#{this.sources_to_s sources}\n</video>"

  sources_to_s: (sources) ->
    s = ""
    sources.each (source) ->
      s += "\n\t<source src=\"#{source.src}\" />"
    s

  setVideoDimensionsToInputFields: (url) ->
    if this.isUrl url
      if $('video-dimensions-ajax-loading')
        $('video-dimensions-ajax-loading').show()
      else
        spinner = new Element 'img',
          id: 'video-dimensions-ajax-loading'
          src: ''
          className: 'ajax-loading'
        $('mp4_normal').appendChild spinner

      SublimeVideoSizeChecker.getVideoSize url, (u, dimensions) =>
        new_width  = if dimensions? then dimensions.width else '???'
        new_height = if dimensions? then dimensions.height else '???'
        $('original_width').innerHTML = new_width
        $('original_height').innerHTML = new_height
        $('video-dimensions-ajax-loading').hide()

        if @video_dimensions['width'] is null
          $('final_width').value = @video_dimensions['width'] = $('original_width').innerHTML
        this.updateDimensionField 'height', @video_dimensions['width']
        this.updateLivePreviewAndDisplayCode()

  updateDimensionField: (field, size) ->
    oppositeField = this.oppositeDimension(field)

    if $("original_#{oppositeField}").innerHTML != '???' and @video_dimensions[oppositeField] != null
      ratio = parseInt($("original_#{field}").innerHTML) / parseInt($("original_#{oppositeField}").innerHTML)
      $("final_#{field}").value = @video_dimensions[field] = Math.round(size * ratio)

  isUrl: (url) ->
    /^https?:\/\/.+\.\w+(\?+.*)?$/.test url

class Standard extends VideoTagBuilder
  move: ->
    alert "Slithering..."
    super 5

class Lightbox extends VideoTagBuilder
  move: ->
    alert "Slithering..."
    super 5

class IframeEmbed extends VideoTagBuilder
  move: ->
    alert "Slithering..."
    super 5
