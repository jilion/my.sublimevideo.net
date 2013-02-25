#= require hamlcoffee
#= require jquery.spin
#= require video-size-checker/sublimevideo-size-checker.min
#= require crc32
#= require inflection
#
#= require_self
#= require_tree ./video_code

window.MSVVideoCode =
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}
  testAssets:
    poster: "https://cdn.sublimevideo.net/vpa/ms_800.jpg"
    thumbnail: "https://cdn.sublimevideo.net/vpa/ms_192.jpg"
    sources: [
      {
        format: 'mp4'
        quality: 'base'
        src: 'https://cdn.sublimevideo.net/vpa/ms_360p.mp4'
      },
      {
        format: 'mp4'
        quality: 'hd'
        src: 'https://cdn.sublimevideo.net/vpa/ms_720p.mp4'
      },
      {
        format: 'mp4'
        quality: 'mobile'
        src: ''
      },
      {
        format: 'webm'
        quality: 'base'
        src: 'https://cdn.sublimevideo.net/vpa/ms_360p.webm'
      },
      {
        format: 'webm'
        quality: 'hd'
        src: 'https://cdn.sublimevideo.net/vpa/ms_720p.webm'
      }
    ]
