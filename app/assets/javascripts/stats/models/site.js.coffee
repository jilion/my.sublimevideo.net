#= require ../../models/site

class MSVStats.Models.Site extends MySublimeVideo.Models.Site

  isDemo: ->
    this.get('token') is 'demo'
