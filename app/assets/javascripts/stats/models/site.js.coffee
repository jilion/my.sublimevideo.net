class MSVStats.Models.Site extends Backbone.Model
  defaults:
    token: null
    hostname: null
    selected: false

  title: ->
    this.get('hostname') || this.get('token')

class MSVStats.Collections.Sites extends Backbone.Collection
  model: MSVStats.Models.Site
  url: '/sites'

  select: (token) ->
    MSVStats.sites.each (site) ->
      site.set(selected: (site.get('token') == token), { silent: true })
    MSVStats.sites.trigger('change')

  selectedSite: ->
    MSVStats.sites.find (site) ->
      site.get('selected')
