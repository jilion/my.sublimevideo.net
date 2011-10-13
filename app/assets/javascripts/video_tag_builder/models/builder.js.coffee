class MSVVideoTagBuilder.Models.Builder extends Backbone.Model
  defaults:
    builderClass: 'standard'
    loader: null
    video: null
    preview: null

  setup: ->
    @poster           = $("##{this.get('poster_id')}")
    @sources          = $(".#{this.get('sources_class')}")
    @keep_video_ratio = $("##{this.get('keep_video_ratio_id')}")

    # The <video> element generated from the settings provided by the user
    @video = null

    # The <video> element classes, 'sublime' by default
    @video_classes = 'sublime'

    # Final video size
    @video_dimensions = { width: null, height: null }

    sublimevideo.load()
    sublimevideo.ready =>
      # this.setupObservers()

class MSVVideoTagBuilder.Models.StandardBuilder extends MSVVideoTagBuilder.Models.Builder


class MSVVideoTagBuilder.Models.LightboxBuilder extends MSVVideoTagBuilder.Models.StandardBuilder


class MSVVideoTagBuilder.Models.IframeEmbedBuilder extends MSVVideoTagBuilder.Models.StandardBuilder


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

# class BPData
#   constructor: ->
#     @bp    = {}
#     @total = 0
# 
#   set: (bp, hits) ->
#     if _.isUndefined(@bp[bp])
#       @bp[bp] = hits
#     else
#       @bp[bp] += hits
#     @total += hits
# 
#   percentage: (hits) ->
#     Highcharts.numberFormat (hits / @total * 100), 2
# 
#   cssClass: (bp) ->
#     bp = bp.split('-')
#     "b_#{bp[0]} p_#{bp[1]}"
# 
#   toArray: ->
#     datas = _.reduce(@bp, (memo, hits, bp) ->
#       memo.push([bp, hits]) if hits > 0
#       memo
#     [])
#     _.sortBy(datas, (data) -> data[1]).reverse()
# 
#   isEmpty: ->
#     @total == 0
# 
#   bpName: (bp) ->
#     bp.split('-').map( (name) ->
#       switch name
#         when 'fir' then 'Firefox'
#         when 'chr' then 'Chrome'
#         when 'iex' then 'IE'
#         when 'saf' then 'Safari'
#         when 'and' then 'Android'
#         when 'rim' then 'BlackBerry'
#         when 'weo' then 'webOS'
#         when 'ope' then 'Opera'
#         when 'win' then 'Windows'
#         when 'osx' then 'Macintosh'
#         when 'ipa' then 'iPad'
#         when 'iph' then 'iPhone'
#         when 'ipo' then 'iPod'
#         when 'lin' then 'Linux'
#         when 'wip' then 'Windows Phone'
#         when 'oth' then 'Other'
#         when 'otm' then 'Other (Mobile)'
#         when 'otd' then 'Other (Desktop)'
#         else name
#     ).join(' - ')
# 
# class MDData
#   constructor: ->
#     # Media
#     @mh = 0
#     @mf = 0
#     # Devise
#     @dh =
#       'Desktop': 0
#       'Mobile': 0
#       'Tablet': 0
#     @df =
#       'Desktop': 0
#       'Mobile': 0
#       'Tablet': 0
# 
#     @total = 0
# 
#   percentage: (hits, total = this.total) ->
#     Highcharts.numberFormat (hits / total * 100), 2
# 
#   set: (md) ->
#     _.each(md.h, (hits, dh) ->
#       @mh     += hits
#       @total  += hits
#       switch dh
#         when 'd' then this.dh['Desktop'] += hits
#         when 'm' then this.dh['Mobile']  += hits
#         when 't' then this.dh['Tablet']  += hits
#     , this)
#     _.each(md.f, (hits, df) ->
#       @mf     += hits
#       @total  += hits
#       switch df
#         when 'd' then this.df['Desktop'] += hits
#         when 'm' then this.df['Mobile']  += hits
#         when 't' then this.df['Tablet']  += hits
#     , this)
# 
#   toArray: (field) ->
#     datas = _.reduce(this[field], (memo, hits, key) ->
#       memo.push([key, hits]) if hits > 0
#       memo
#     [])
#     _.sortBy(datas, (data) -> data[1]).reverse()
# 
#   isEmpty: ->
#     @total == 0
